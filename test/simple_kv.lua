local exports = {}

local dnode = require('..')
local Object = require('core').Object
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

local function KvServer()
  local db = { }
  local self = dnode:new({
	  load = function(key, reply)
      reply(db[key])
	  end,
	
    -- block is a function called if the key 
    -- is not available and return its return 
    -- value. If block is not a function it is
    -- used as is.
	  fetch = function(key, reply, block)-- ... --[[ options, block ]]) 
      local value = db[key]
      if value == nil then
        if type(block) == 'function' then
          block(function(block_result)
             db[key] = block_result 
             reply(block_result) 
          end) 
        else 
          db[key] = block

          reply(block)
        end
      else
        reply(value) 
      end
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
  })

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

    client:connect(address.port, function(db, conn)
      conn:destroy()
      server:destroy()
      test.done()
	  end)
  end)
end

exports['test_kv_server_load'] = function(test)
	local server = KvServer()

  local client = dnode:new()
  client:on('remote', function(db, conn)
    db.store('foo', 'bar', function()
      db.load('foo', function(val)
        asserts.equals(val, 'bar')
        asserts.equals(server.db.foo, 'bar')

        conn:destroy()
        server:destroy()
        test.done()
      end)
    end)
  end)

  client:pipe(server)
  server:pipe(client)
end

exports['test_kv_server_load_returns_nil'] = function(test)
	local server = KvServer()

  local client = dnode:new()
  client:on('remote', function(db, conn)
    db.load('foo', function(val)
      asserts.equals(val, nil)
      asserts.equals(server.db.foo, nil)

      conn:destroy()
      server:destroy()
      test.done()
    end)
  end)

  client:pipe(server)
  server:pipe(client)
end

exports['test_kv_server_store'] = function(test)
	local server = KvServer()

  local client = dnode:new()
  client:on('remote', function(db, conn)
    db.store('foo', 'bar', function(old_value)
      asserts.equals(old_value, nil)
      asserts.equals(server.db.foo, 'bar')

      db.store('foo', 'baz', function(old_value)
        asserts.equals(old_value, 'bar')
        asserts.equals(server.db.foo, 'baz')

        conn:destroy()
        server:destroy()
        test.done()
      end)
    end)
  end)

  client:pipe(server)
  server:pipe(client)
end

exports['test_kv_server_fetch'] = function(test)
	local server = KvServer()

  local client = dnode:new()
  client:on('remote', function(db, conn)
    db.store('foo', 'bar', function(old_value)
      asserts.equals(old_value, nil)

      db.fetch('foo', function(val)
        asserts.equals(val, 'bar')
        asserts.equals(server.db.foo, 'bar')

        conn:destroy()
        server:destroy()
        test.done()
      end)
    end)
  end)

  client:pipe(server)
  server:pipe(client)
end

exports['test_kv_server_fetch_returns_nil'] = function(test)
	local server = KvServer()

  local client = dnode:new()
  client:on('remote', function(db, conn)
    db.fetch('foo', function(val)
      asserts.equals(val, nil)
      asserts.equals(server.db.foo, nil)

      conn:destroy()
      server:destroy()
      test.done()
    end)
  end)

  client:pipe(server)
  server:pipe(client)
end

exports['test_kv_server_fetch_block_value'] = function(test)
	local server = KvServer()

  local client = dnode:new()
  client:on('remote', function(db, conn)
    db.fetch('foo', function(val)
      asserts.equals(val, 'default')
      asserts.equals(server.db.foo, 'default')

      conn:destroy()
      server:destroy()
      test.done()
    end, 'default')
  end)

  client:pipe(server)
  server:pipe(client)
end

exports['test_kv_server_fetch_block_function'] = function(test)
	local server = KvServer()

  local client = dnode:new()
  client:on('remote', function(db, conn)
    db.fetch('foo', function(val)
      asserts.equals(val, 'default')
      asserts.equals(server.db.foo, 'default')

      conn:destroy()
      server:destroy()
      test.done()
    end, function(reply)
      reply('default')
    end)
  end)

  client:pipe(server)
  server:pipe(client)
end

exports['test_kv_server_delete'] = function(test)
	local server = KvServer()

  local client = dnode:new()
  client:on('remote', function(db, conn)
    db.store('foo', 'bar', function(old_value)
      asserts.equals(old_value, nil)
      asserts.equals(server.db.foo, 'bar')

      db.delete('foo', function(val)
        asserts.equals(val, 'bar')
        asserts.equals(server.db.foo, nil)

        conn:destroy()
        server:destroy()
        test.done()
      end)
    end)
  end)

  client:pipe(server)
  server:pipe(client)
end

exports['test_kv_server_has_key'] = function(test)
	local server = KvServer()

  local client = dnode:new()
  client:on('remote', function(db, conn)
    db.has_key('foo', function(exist)
      asserts.ok(not exists)
    end)

    db.store('foo', 'bar', function(old_value)
      asserts.equals(old_value, nil)
      asserts.equals(server.db.foo, 'bar')

      db.has_key('foo', function(exist)
        asserts.ok(exist)
        asserts.equals(server.db.foo, 'bar')

        conn:destroy()
        server:destroy()
        test.done()
      end)
    end)
  end)

  client:pipe(server)
  server:pipe(client)
end

return exports
