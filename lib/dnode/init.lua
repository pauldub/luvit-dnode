local net = require('net')

local Server = require('./server')
local Queue = require('./queue')

local function listen(self, cons, port, opts)
  self.sessions = Queue:new()
  self.server = net.createServer(function(socket)
    local d = Server:new(cons, opts)
    self.sessions:rpush(socket)
    local session_id = self.sessions.last  
    
    d:on('end', function()
      self.sessions.list[session_id] = nil
      self.sessions = Queue:new(self.sessions.list)
    end)

    d:on('error', function(err)
      print(err)
      print_keys(err)
      d:emit('error', err)
    end)
    
    d.stream = socket
    socket:pipe(d)
    d:pipe(socket)
  end)
  self.server:listen(port)
  return self
end

return {
	Proto = require('./proto'),
	Client = require('./client'),
	Server = Server,
  listen = listen
}
