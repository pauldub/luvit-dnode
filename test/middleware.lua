local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

local done = function(server, test)
	server:destroy()
	test.done()
end

-- This test is not complete yet: see https://github.com/substack/dnode/blob/master/test/middleware.js
-- It looks like conn:on('remote', ...) is not called :(
exports['test_middleware'] = function(test)
	local server = dnode:new(function(self, client, conn)
		asserts.ok(not conn.zing)
		asserts.ok(not client.moo)

		conn:on('remote', function(remote, c)
			-- Hmmm, I'm wondering what makes this fail.
			-- asserts.ok(client.moo)
			-- asserts.ok(conn.zing)
		end)

		return { baz = 42 }
	end)

	server:on('local', function(client, conn)
		conn.zing = true
		print('1', conn.id)
	end)

	server:on('local', function(client, conn)
		client.moo = true
		print('2', conn.id)
	end)

	server:listen(1337)

	local client = dnode:new():connect(1337, function(remote, conn)
		asserts.ok(remote.baz)
	
		done(server, test)
	end)
end

return exports

