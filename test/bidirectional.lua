local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

exports['test_bidirectionnal'] = function(test)
	local server = dnode:new(function(d, client, conn)
		return {
			timesX = function(n, f)
				asserts.equals(n, 3, 'timesX n == 3')

				client.x(function(x)
					asserts.equals(x, 20, 'client.x == 20')

					f(n * x)
				end)
			end
		}
	end)

	local client = dnode:new({
		x = function(f, b) 
			f(20)
		end
	})

	client:on('remote', function(remote, conn)
		remote.timesX(3, function(res)
			asserts.equals(res, 60, 'result of 20 * 3 == 60')
			server:destroy()
			test.done()
		end)
	end)

	client:pipe(server)
	server:pipe(client)
end

return exports
