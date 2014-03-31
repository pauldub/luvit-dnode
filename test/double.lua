local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

exports['test_double'] = function(test)
	local server = dnode:new({
		z = function(f, g ,h)
			f(10, function(x)
				g(10, function(y)
					h(x, y)
				end)
			end)
		end
	})

	local client = dnode:new()
	client:on('remote', function(remote, conn)
		remote.z(function(x, f)
			f(x * 2)
		end, function(x, f)
			f(x / 2)
		end, function(x, y)
			asserts.equals(x, 20, 'double not equal')
			asserts.equals(y, 5, 'double not equal')
		end)

		local plusTen = function(n, f)
			f(n + 10)
		end

		remote.z(plusTen, plusTen, function(x, y)
			asserts.equals(x, 20, 'double not equal')
			asserts.equals(y, 20, 'double not equal')

			server:destroy()
			test.done()
		end)
	end)

	client:pipe(server)
	server:pipe(client)
end

return exports

