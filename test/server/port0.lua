local exports = {}

local dnode = require('../..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

exports['test_port_0'] = function(test)
	local port = 0
	local node = dnode:new()

	node:listen(port, function()
		local address = node.net:address()

		asserts.assert(address.port ~= port, 'adress.port ~= port')
		asserts.assert(address.port > 0, 'address.port > 0')

		node:destroy()
		test.done()
	end)
end

return exports

