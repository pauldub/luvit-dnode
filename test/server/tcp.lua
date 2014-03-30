local exports = {}

local dnode = require('../..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

exports['test_tcp'] = function(test)
	local port = 1337
	local server = dnode:new({
		timesTen = function(n, reply)
			asserts.equals(n.number, 5)

			reply(n.number * 10)
		end,

		print = function(n, reply)
			reply(utils.dump(n))
		end
	})
		
	server:listen(port, function()
		dnode:new():connect(port, function(remote, conn)
			asserts.equals(conn.stream.remoteAddress, '127.0.0.1')

			local args = {
				number = 5,
				func = function() end
			}

			remote.timesTen(args, function(m)
				asserts.equals(m, 50, '5 * 10 == 50')

				conn:destroy()
				server:destroy()
				test.done()
			end)
		end)
	end)
end

return exports


