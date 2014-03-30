local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

local done = function(server, test)
	server:close()
	test.done()
end

-- This test is not complete yet: see https://github.com/substack/dnode/blob/master/test/middleware.js
-- It looks like conn:on('remote', ...) is not called :(
exports['test_middleware'] = function(test)
	local server = dnode:new(function(self, client, conn)
		self:on('local', function(client, conn)
			conn.zing = true
		end)

		self:on('local', function(client, conn)
			client.moo = true

			conn:on('remote', function()
				print('okok')
			end)
		end)

		asserts.ok(not conn.zing)
		asserts.ok(not client.moo)

		conn:on('remote', function()
			print(utils.dump(conn))
			asserts.ok(conn.zing)
			asserts.ok(self.moo)
		end)

		return { baz = 42 }
	end):listen(1337)


	local client = dnode:new():connect(1337, function(remote, conn)
		asserts.ok(remote.baz)
	
		done(server, test)
	end)
end

return exports

