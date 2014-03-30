local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

exports['test_client_server_calls'] = function(test)
	local port = 3094

	local server = dnode:listen({
		zing = function(n, cb)
			asserts.equals(33, n)

			cb(false, n + 100)
		end
	}, port)

	dnode:connect(port, function(remote, conn)
		remote.zing(33, function(err, result)
			asserts.not_ok(err)
			asserts.equals(133, result)

			server.net:close()
			test.done()
		end)
	end)

end

return exports

