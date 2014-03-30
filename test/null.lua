local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

local done = function(server, test)
	server:destroy()
	test.done()
end

exports['test_simple_server_and_client'] = function(test)
	local server = dnode:new({ 
		empty = nil,

		timesTen = function(n, reply)
			asserts.equal(n, 50)
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

	local client = dnode:new()
	client:on('remote', function(remote, conn)
		remote.moo(function(x)
			asserts.equals(x, 100, 'remote moo == 100')
		end)

		remote.sTimesTen(5, function(m)
			asserts.equals(m, 50, '5 * 10 == 50')

			remote.timesTen(m, function(n)
				asserts.equals(n, 500, '50 * 10 == 500')
				done(server, test)
			end)
		end)
	end)

	client:pipe(server)
	server:pipe(client)
	--server:on('error', function() done(server, test) end)
	--client:on('error', function() done(server, test) end)
end


return exports

