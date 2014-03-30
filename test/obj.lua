local exports = {}

local dnode = require('..')
local utils = require('utils')
local asserts = require('bourbon/lib/asserts')

exports['test_object_refs'] = function(test)
	local obj = {
		a = 1,
		b = 2,
		f = function(n, g)
			g(n * 20)
		end
	}

	local server = dnode:new({ 
		getObject = function(f)
			f(obj)
		end
	}):listen(1337)

	local client = dnode:new():connect(1337, function(remote, conn)
		remote.getObject(function(rObj)
			asserts.equals(rObj.a, 1)
			asserts.equals(rObj.b, 2)
			asserts.equals(type(rObj.f), 'function')

			rObj.a = rObj.a + 100
			rObj.b = rObj.b + 100

			asserts.equals(obj.a, 1)
			asserts.equals(obj.b, 2)

			asserts.assert(obj.f ~= rObj.f, 'obj.f == rObj.f')
			asserts.equals(type(obj.f), 'function')

			rObj.f(13, function(ref)
				asserts.equals(ref, 260)

				server.net:close()
				test.done()
			end)
		end)
	end)
end

return exports

