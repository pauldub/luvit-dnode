local Emitter = require('core').Emitter

local table = require('table')

local Scrubber = require('./scrubber')

local Logger = require('./logger')
local logger = Logger:new('protocol')

local Protocol = Emitter:extend()
function Protocol:initialize(cons, opts)
	self.logger = logger
	self.opts = opts or {}
	self.remote = {}
	self.callbacks = { locals = {}, remote = {} }
	self.wrap = self.opts.wrap	
	self.unwrap = self.opts.unwrap
	
	self.scrubber = Scrubber:new(self.callbacks.locals)

  if type(cons) == 'function' then 
    self.instance = cons(self.remote, self) 
  else
    self.instance = cons or {} 
  end
end

function Protocol:start()
	logger.debug("protocol started")
	self:request('methods', { self.instance } )
end

function Protocol:request(method, args)
	local scrub = self.scrubber:scrub(args)
  logger.debug('request', method, scrub)	
	self:emit('request', {
		method = method,
		arguments = scrub.arguments,
		callbacks = scrub.callbacks,
		links = scrub.links
	})
end

function Protocol:handle(req)
	local args = self.scrubber:unscrub(req, function(id)
    logger.debug('handle id: ', id)
    return function(...)
      local args = {...}
      logger.debug('req cb', id, args)
      self:request(id, args)
    end
  end)

  logger.debug('req.method:', req.method, type(req.method))
  logger.debug('handle args', args)

  if req.method == 'methods' then
    -- Validate args.
		self:handleMethods(args[1])
	elseif req.method == 'cull' then
	  for i,id in ipairs(args) do
      self.callbacks.remote[id] = nil
    end
  elseif type(req.method) == 'string' then
    local method = self.instance[req.method]
    logger.debug('method:', method, 'type:', type(method))
    if method and type(method) == 'function' then
      logger.debug('apply instance func:', req.method)
      local result
      local status, err = pcall(function()
        method(unpack(args), function(res)
          logger.debug('request res:', res)
          result = res
        end)
      end) 
      if err then
        logger.debug('error:', err)
        -- TODO: return it?
      else
        return result
      end
    end
  elseif type(req.method) == 'number' then
    local fn = self.scrubber.callbacks.list[req.method]
    if fn == nil then
      self:emit('fail', 'no such method')
    else
      fn(unpack(args))
    end end
end

function Protocol:handleMethods(methods)
  for k,_ in pairs(self.remote) do
    self.remote[k] = nil
  end
  for k,m in pairs(methods) do
    self.remote[k] = m
  end
  
  self:emit('remote', self.remote)
end

return Protocol
