local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

exports['test_client_server_calls'] = function(test)
	local server = dnode:new({
		zing = function(n, cb)
			asserts.equals(33, n)

			cb(false, n + 100)
		end
	})

	local client = dnode:new()
	client:on('remote', function(remote, conn)
		remote.zing(33, function(err, result)
			asserts.not_ok(err)
			asserts.equals(133, result)

			server:destroy()
			test.done()
		end)

	end)
	
	client:pipe(server)
	server:pipe(client)
end

return exports

