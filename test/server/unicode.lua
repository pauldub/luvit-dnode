local exports = {}

local dnode = require('../..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

exports['test_unicode'] = function(test)
	local port = 1337

	local server = dnode:new({
		unicodes = function(reply)
			reply('☔☔☔☁☼☁❄')
		end
	})

	server:listen(port, function()
		dnode:new():connect(port, function(remote, conn)
			asserts.equals(conn.stream.remoteAddress, '127.0.0.1')

			remote.unicodes(function(str)
				asserts.equals(str, '☔☔☔☁☼☁❄', 'remote unicodes == ☔☔☔☁☼☁❄')

				conn:destroy()
				server:destroy()
				test.done()
			end)
		end)

	end)
end

return exports

