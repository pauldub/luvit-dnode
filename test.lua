local net = require('net')
local dnode = require('.')


dnode:listen(function(remote, conn)
  print('ok')
  return {
    zing = function(n, cb)
      cb(n * 100)
    end
  }
end ,7070)
