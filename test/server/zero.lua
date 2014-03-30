local exports = {}

local dnode = require('../..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

exports['test_listen_on_port_0'] = function(test)
	local server = dnode:new({
		timesTen = function(n, reply)
			asserts.equals(n, 50)

			reply(n * 10)
		end,

		moo = function(reply)
			reply(100)
		end,

		sTimesTen = function(n, cb)
			asserts.equals(n, 5)

			cb(n * 10)
		end
	})

	server:listen(0, function()
		local port = server.net:address().port

		dnode:new():connect(port, function(remote, conn)
			asserts.ok(conn.id)
			asserts.equals(conn.stream.remoteAddress, '127.0.0.1')

			remote.moo(function(x)
				asserts.equals(x, 100, 'remote moo == 100')
			end)

			remote.sTimesTen(5, function(m)
				asserts.equals(m, 50, '5 * 10 == 50')
				
				remote.timesTen(m, function(n)
					asserts.equals(n, 500, '50 * 10 == 500')

					conn:destroy()
					server:destroy()
					test.done()
				end)
			end)
		end)
	end)
end

return exports

