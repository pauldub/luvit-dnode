local net = require('net')

local Server = require('./server')
local Client = require('./client')
local Queue = require('./queue')

local function connect(self, port, block)
  local self = Server:new({}, opts)

  self:on('remote', block)

  socket = net.createConnection(port, function()
    socket:on('error', function(err)
      self:emit('error', err)
      socket:done()
    end)  

    self.stream = socket
    socket:pipe(self)
    self:pipe(socket) 
    return self
  end)
end

local function listen(self, cons, port, opts)
  self.sessions = Queue:new()
  self.server = net.createServer(function(socket)
    local d = Server:new(cons, opts)
    self.sessions:rpush(socket)
    local session_id = self.sessions.last  
    
    d:on('end', function()
      socket:destroy()
      self.sessions.list[session_id] = nil
      self.sessions = Queue:new(self.sessions.list)
    end)

    socket:on('error', function(err)
      d:destroy()
      socket:done()
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
  connect = connect,
  listen = listen
}
