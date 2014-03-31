local exports = {}

local dnode = require('..')
local Object = require('core').Object
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

local function KvServer()
  local db = { }
  local interface = {
	  load = function(key, reply)
      reply(db[key])
	  end,
	
	  fetch = function(key, reply, block)-- ... --[[ options, block ]]) -- block is a function called if the key 
                                                             -- is not available and return its return 
	                                                           -- value. If block is not a function it is
                                                             -- used as is.
      local value = db[key]
      if value == nil then
         value = type(block) == 'function' and block() or block
         db[key] = value
      end
      reply(value) 
    end,

    store = function(key, value, reply) -- ... --[[ options, reply ]])
      local old_value = db[key]

      db[key] = value

      reply(old_value)
    end,

    delete = function(key, reply) --... --[[ options, reply ]])
      local value = db[key]

      db[key] = nil
      
      reply(value)
    end,

    has_key = function(key, reply)
      reply(db[key] ~= nil)
    end,
  }

  local self = dnode:new(interface)
  self.db = db
  return self
end

exports['test_kv_server_can_listen'] = function(test)
	local server = KvServer()

  server:listen(0, function()
	  local client = dnode:new()

    local address = server.net:address()
    asserts.ok(address)
    asserts.ok(address.port)

    client:connect(address.port, function(remote, conn)
      conn:destroy()
      server:destroy()
      test.done()
	  end)
  end)
end

exports['test_kv_server_fetch'] = function(test)
	local server = KvServer()

  local client = dnode:new()
  client:on('remote', function(remote, conn)
    remote.fetch('foo', function(old_val)
      asserts.equals(old_val, 'default')
      asserts.equals(server.db.foo, 'default')

      conn:destroy()
      server:destroy()
      test.done()
    end, 'default')
  end)

  client:pipe(server)
  server:pipe(client)
end

return exports
