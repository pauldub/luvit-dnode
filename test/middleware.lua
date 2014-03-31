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

		conn:on('remote', function(c, b, d)
			asserts.ok(conn.zing)
			-- Hmmm, I'm wondering what makes this fail.
			-- asserts.ok(client.moo)
		end)

		return { baz = 42 }
	end)

	server:on('local', function(client, conn)
		conn.zing = true
	end)

	server:on('local', function(client, conn)
		client.moo = true
	end)

	local client = dnode:new()
	client:on('remote', function(remote, conn)
		asserts.ok(remote.baz)
	
		done(server, test)
	end)
	
	client:pipe(server)
	server:pipe(client)
end

return exports

