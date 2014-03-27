local Emitter = require('core').Emitter
local Queue = require('./queue')
local Scrubber = require('./scrubber')
local json = require('json4lua/json4lua/json/json.lua')
local table = require('table')
local utils = require('utils')

local Protocol = Emitter:extend()
function Protocol:initialize(cons, opts)
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
	print("protocol started")
	self:request('methods', { self.instance } )
end

function Protocol:request(method, args)
	local scrub = self.scrubber:scrub(args)
  print('proto - request', method, utils.dump(scrub))	
	self:emit('request', {
		method = method,
		arguments = scrub.arguments,
		callbacks = scrub.callbacks,
		links = scrub.links
	})
end

function Protocol:handle(req)
	local args = self.scrubber:unscrub(req, function(id)
    print('proto - handle id: ', id)
    local cb = function(...)
      local args = {...}
      print('proto - req cb', id, utils.dump(args))
      self:request(id, args)
    end
    self.callbacks.remote[id] = cb
    return cb
  end)

  local remote_cb, id

  -- for k,v in pairs(self.callbacks.remote) do
    -- if v == cb then
      -- remote_cb = k
    -- end
  -- end
	-- if remote_cb == nil then
    -- id = #self.callbacks.remote.list + 1
		-- local cb = function() 
			-- -- TODO: Here args is probably wrong...
       -- print('in cb')
			-- self:request(id, args)
		-- end	
-- 
    -- self.callbacks.remote:rpush(cb)
    -- print('remote-cb id', id)
		-- remote_cb = self.wrap and self:wrap(cb, id) or cb
  -- else
    -- id = remote_cb
    -- print('remote_cb k:', k)
    -- remote_cb = self.callbacks.remote[id]
  -- end	

  print('proto - req.method:', req.method, type(req.method))
  print('proto - handle args', utils.dump(args))

  if req.method == 'methods' then
    -- Validate args.
		self:handleMethods(args[1])
	elseif req.method == 'cull' then
	  for i,id in ipairs(args) do
      self.callbacks.remote[id] = nil
    end
  elseif type(req.method) == 'string' then
    local method = self.instance[req.method]
    print('proto - method:', method, 'type:', type(method))
    if method and type(method) == 'function' then
      print('proto - apply instance func:', req.method)
      local result
      local status, err = pcall(function()
        method(unpack(args), function(res)
          print('proto - request res:', res)
          result = res
        end)
      end) 
      if err then
        print('proto - error:', err)
        -- TODO: return it?
      else
        return result
      end
    end
  elseif type(req.method) == 'number' then
    local fn = self.scrubber.callbacks.list[req.method - 1]
    print(utils.dump(self.scrubber.callbacks))
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
