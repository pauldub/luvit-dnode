local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

exports['test_client_server_calls'] = function(test)
	local port = 3094

	local server = dnode:new({
		zing = function(n, cb)
			asserts.equals(33, n)

			cb(false, n + 100)
		end
	}):listen(port)

	dnode:new():connect(port, function(remote, conn)
		remote.zing(33, function(err, result)
			asserts.not_ok(err)
			asserts.equals(133, result)

			server:close()
			test.done()
		end)
	end)

end

return exports

