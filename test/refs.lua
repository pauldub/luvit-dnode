local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

exports['test_refs'] = function(test)
	local server = dnode:listen({ a = 1, b = 2}, 1337)
	local client = dnode:connect(1337, function(remote, conn)
		asserts.equals(remote.a, 1)
		asserts.equals(remote.b, 2)

		server.net:close()
		test.done()
	end)
end

return exports

