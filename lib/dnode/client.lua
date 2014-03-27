local Emitter = require('core').Emitter
local iStream = require('core').iStream
local json = require('json4lua/json4lua/json/json.lua')

local Queue = require('./queue')
local Scrubber = require('./scrubber')

function print_keys(table)
  for k,_ in pairs(table) do
    print('key:', k)
  end 
end

--local Protocol = require('./proto')

local Client = iStream:extend()
function Client:initialize(cons, opts)
	self.opts = opts or {}

	self.cons = cons

	self.readable = true
	self.writable = true

	self.queue = {}

  process.nextTick(function()
	  if self.ended then 
		  return 
	  end
	
	  self.proto = self:createProto()
	  self.proto:start()
  
	  if self.handle_queue == nil then
		  return
	  end

	  -- TODO: Use lua async or lua functional for list ops.
	  for i,row in ipairs(self.queue) do
		  self:handle(self.queue[i])
	  end
  end)
end

function Client:createProto()
	local proto = Protocol:new(function(proto, remote)
		-- TODO: Check if self refers to the correct object
		if self.ended then
			print("proto ended")
			return
		end

		local ref = self.cons(self, proto, remote)

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
			self:emit('data', json.encode(req))
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

function Client:write(buf)
  if self.ended then
    return
  end

  if buf and type(buf) == 'string' then
    if self._line == nil then
      self._line = ''
    end    
    buf:gsub('.', function(c)
      -- print(c:byte())
      if c:byte() == 0x0a then
        local row
        local status, err = pcall(function()
          row = json.decode(self._line)
        end)
        if err then
          print('server - cannot parse json:', err)
          self:destroy()
        end
        self._line = ''
        self:handle(row)
      else
        self._line = self._line .. c
      end
    end)
  end
end

function Client:handle(row)
	if self.proto == nil then
		print("server - handle no proto")
		self.handle_queue = self.handle_queue or Queue:new()
		self.handle_queue:rpush(row)
		return
	else
		print("server - handle proto")
		local status, err = pcall(function() self.proto:handle(row) end)
    if err then
      print('server - error:', err)
    end
	end
end

function Client:destroy()
	if self.ended then
		return
	end

	self.ended = true
	self.writable = false
	self.readable = false
	
	self:emit('end')
end


return Client
