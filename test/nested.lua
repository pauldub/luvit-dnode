local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

local timer = require('timer')
local Emitter = require('core').Emitter

-- This test is not really readable, there is probably something
-- wrong with dnode:listen, I have to close the dnode connections
-- and then close the tcp connections.

exports['test_nested'] = function(test)
	local server1 
	local net1 = dnode:new(function(self, remote, conn)
		server1 = conn

		return {
			timesTen = function(n, reply)
				reply(n * 10)
			end
		}
	end):listen(1337)

	local server2 
	local net2 = dnode:new(function(self, remote, conn)
		server2 = conn

		return {
			timesTwenty = function(n, reply)
				reply(n * 20)
			end
		}
	end):listen(1338)

	local moo = Emitter:new()

	local client1 = dnode:new():connect(1337, function(remote1, conn)
		local client2 = dnode:new():connect(1338, function(remote2, conn)
			moo:on('hi', function(x)
				remote1.timesTen(x, function(res)
					asserts.equals(res, 5000, 'emitted value times ten')

					remote2.timesTwenty(res, function(res2)
						asserts.equals(res2, 100000, 'result times twenty')

						moo:emit('end')
					end)
				end)
			end)

			remote2.timesTwenty(5, function(n)
				asserts.equals(n, 100)

				remote1.timesTen(0.1, function(n)
					asserts.equals(n, 1)
				end)
			end)
		end)
	end)

	moo:on('end', function()
		server1:destroy()
		server2:destroy()
		net1:close()
		net2:close()
		test.done()
	end)

	timer.setTimeout(200, function()
		moo:emit('hi', 500)
	end)
end

return exports

