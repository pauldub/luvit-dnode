local net = require('net')
local dnode = require('.')
local utils = require('utils')

dnode:connect(7070, function(remote, conn)
  print(utils.dump(remote))  
  remote.zing(33, function(n)
    print('n='..n)
  end)
end)