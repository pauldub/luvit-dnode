local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

exports['test_refs'] = function(test)
	local server = dnode:new({ a = 1, b = 2})

	local client = dnode:new()
	client:on('remote', function(remote, conn)
		asserts.equals(remote.a, 1)
		asserts.equals(remote.b, 2)

		server:destroy()
		test.done()
	end)

	client:pipe(server)
	server:pipe(client)
end

return exports

