local net = require('net')
local dnode = require('.')

local node

function start()
  return dnode:listen(function(remote, conn)
    return {
      --[[foo = function(n, cb)
        print("foo called with:", n)
        cb(n - 100)
      end,
      bar = function(n, cb)
        print("bar called with:", n)
        cb(n)
      end,
      ]]
      zing = function(n, cb)
        print("zing called with:", n)
        cb(n * 100)
      end
    }
  end ,7070)
end


node = start()

print('started node')
