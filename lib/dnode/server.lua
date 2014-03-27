local core = require('core')
local native = require('uv_native')
local iStream = require('core').iStream
local fun = require('lua-functional/lua-functional')
local json = require('json4lua/json4lua/json/json.lua')

local Queue = require('./queue')

function print_keys(table)
  for k,_ in pairs(table) do
    print('key:', k)
  end 
end

local Scrubber = core.Emitter:extend()
function Scrubber:initialize(callbacks)
  self.callbacks = Queue:new(callbacks)
end

function Scrubber:scrub(obj)
  local paths = {}
  local links = {}

  local args = fun.map(function(node)
    if node then
      local index = nil
      for i, cb in ipairs(self.callbacks.list) do
        if cb == node then
          index = i 
        end
      end
      
      if index and index > 0 and not paths[index] then
        error('ctx.path?')
        paths[i] = ctx.path
      else
        self.callbacks:rpush(node)
        local id = self.callbacks.last
        paths[id] = self.callbacks.list[id]
      end
    else  
      print("I failed because im badly implemented")
    end 
  end, obj)
  return { arguments = args, callbacks = paths, links = links }
end

function Scrubber:unscrub(msg, f)
  local args = msg.arguments or {}
  -- TODO: Unscrub things.

  return args
end

--local Protocol = require('./proto')
local Protocol = core.Emitter:extend()
function Protocol:initialize(cons, opts)
	self.opts = opts or {}
	self.remote = {}
	self.callbacks = { locals = {}, remote = Queue:new() }
	self.wrap = self.opts.wrap	
	self.unwrap = self.opts.unwrap
	
	self.scrubber = Scrubber:new(self.callbacks.locals)

	self.instance = cons(self.remote, self)
end

function Protocol:start()
	print("protocol started")
	self:request('methods', { self.instance } )
end

function Protocol:request(method, args)
	local scrub = self.scrubber:scrub(args)
  print('proto - request')	
	self:emit('request', {
		method = method,
		arguments = scrub.arguments,
		callbacks = scrub.callbacks,
		links = scrub.links
	})
end

function Protocol:handle(req)
	local args = self.scrubber:unscrub(req)
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

  print('proto - handle args')
  print('proto - req.method:', req.method, type(req.method))
  print(args)
  print_keys(req)

  if req.method == 'methods' and #args > 0 then
    -- Validate args.
		self.handleMethods(args[1])
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
    local fn = self.callbacks.locals[req.method]
    if fn == nil then
      self:emit('fail', 'no such method')
    else
      fun.apply(fn, args)
    end
	end
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

local Server = iStream:extend()
function Server:initialize(cons, opts)
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

function Server:createProto()
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

function Server:write(buf)
  if self.ended then
    return
  end

  print(type(buf))
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

function Server:handle(row)
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
