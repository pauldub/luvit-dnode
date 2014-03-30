local Emitter = require('core').Emitter
local iStream = require('core').iStream

local string = require('string')
local json = require('json')

local Queue = require('./queue')
local Scrubber = require('./scrubber')

local Logger = require('./logger')
local logger = Logger:new('server')

local Protocol = require('./proto')

local Server = iStream:extend()
function Server:initialize(cons, opts)
	self.logger = logger
	self.opts = opts or {}

  if type(cons) == 'function' then
	  self.cons = cons
  else
    self.cons = function()
      return cons
    end
  end

  self.readable = true
	self.writable = true

	self.queue = {}

  process.nextTick(function()
	  if self.ended then 
		  return 
	  end
	
	  self.proto = self:createProto()
    logger.debug('starting')
	  self.proto:start()
  
	  if self.handle_queue == nil then
		  return
	  end

	  -- TODO: Use lua async or lua functional for list ops.
	  for i,row in ipairs(self.queue) do
		  self:handle(self.queue[i])
	  end
  end) end

function Server:createProto()
	local proto = Protocol:new(function(proto, remote)
		-- TODO: Check if self refers to the correct object
		if self.ended then
			logger.info("proto ended")
			return
		end

		local ref 
    if type(self.cons) == 'function' then
      ref = self.cons(self, proto, remote)
    else
      ref = self.cons or {}
    end

		self:emit('local', ref, self)

		return ref or self	
	end, self.opts.proto)

	proto:on('remote', function(remote)
		self:emit('remote', remote, self)
	end)

	proto:on('request', function(req)
		if self.readable == false then
			return
		end

		if self.opts.emit == 'object' then
			self:emit('data', req)
		else
			-- TODO: Stringify json?
      logger.debug('emit data', req.arguments)
      local copy = { }
      for k,v in pairs(req.callbacks) do
        if v then
          copy[k] = v
        end
      end
      req.callbacks = copy
			logger.debug('request json', json.stringify(req))
			self:emit('data', json.stringify(req) .. '\n')
		end
	end)

	proto:on('fail', function(err)
		self:emit('fail', err)
	end)

	proto:on('error', function(err)
		self:emit('error', err)
	end)
	
	return proto
end

function Server:write(buf)
  if self.ended then
    return
  end

	logger.debug('write buf', buf)

  if buf and type(buf) == 'string' then
    if self._line == nil then
      self._line = ''
    end    
    local handled 
    buf:gsub('.', function(c)
      if c:byte() == 0x0a then
        local row
        local status, err = pcall(function()
          row = json.parse(self._line)
        end)
        if err then
          logger.error('cannot parse json:', err)
          self:destroy()
        end
        logger.debug('write row', row)
        self._line = ''
        self:handle(row)
        handled = true
      else
        self._line = self._line .. c
      end
    end)
    --[[ if handled == nil then
      local row
      local status, err = pcall(function()
        row = json.parse(buf)
      end)
      if err then
        logger.fail('cannot parse json buf:', err)
        self:destroy()
      end
      if row then
        logger.debug('write buf row', row.arguments)
        self:handle(row)
			end
    end]]
  end
end

function Server:handle(row)
	logger.debug('handle row', row and row.arguments)
	if self.proto == nil then
		logger.debug("handle no proto")
		self.handle_queue = self.handle_queue or Queue:new()
		self.handle_queue:rpush(row)
		return
	else
		logger.debug("handle proto")
		local status, err = pcall(function() self.proto:handle(row) end)
    if err then
      logger.error('error:', err)
    end
	end
end

function Server:destroy()
	if self.ended then
		return
	end

	self.ended = true
	self.writable = false
	self.readable = false
	
	self:emit('end')
end


return Server
