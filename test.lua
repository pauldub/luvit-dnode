local net = require('net')
local dnode = require('.')

local node

function start()
  return dnode:listen(function(remote, conn)
    return {
      zing = function(n, cb)
        print("zing called with:", n)
        cb(n * 100)
      end
    }
  end ,7070)
end


node = start()

print('started node')
