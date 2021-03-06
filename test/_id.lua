local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

-- It should work using dnode:new() only, but it looks like
-- read/write doesn't do it. So for now lets use simple tcp 
-- servers. Just remember to close them.
exports['test_id'] = function(test)
	local server = dnode:new({ _id = 1337 })

	local client = dnode:new()
	
	client:on('remote', function(remote, conn)
		asserts.equals(remote._id, 1337)

		conn:destroy()
		server:destroy()
		test.done()
	end)

	client:pipe(server)
	server:pipe(client)
end

return exports
