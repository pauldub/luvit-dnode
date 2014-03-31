local exports = {}

local dnode = require('../..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

local net = require('net')

exports['test_stream'] = function(test)
	local port = 1337

	local server = net.createServer(function(stream)
		local d = dnode:new({
			meow = function(g) 
				g('cats')
			end
		})

		d:on('remote', function(remote)
			asserts.equals(remote.x, 5)
		end)

		stream:pipe(d)
		d:pipe(stream)
	end)

	server:listen(port, function()
		local d = dnode:new({ x = 5 })

		d:on('remote', function(remote)
			remote.meow(function(cats)
				asserts.equals(cats, 'cats')

				server:close()
				test.done()
			end)
		end)

		local stream = net.createConnection(port)
		d:pipe(stream)
		stream:pipe(d)
	end)
end

return exports


