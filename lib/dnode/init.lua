local net = require('net')
local bind = require('utils').bind

local Server = require('./server')
local Queue = require('./queue')

local function connect(self, port, block, cons)
  local self = Server:new(cons or {}, opts)

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
  self.net = net.createServer(function(socket)
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

  self.net:listen(port)

  return self
end

local function new(self, cons, opts)
	return Server:new(cons or {}, opts)
end

return {
	Proto = require('./proto'),
	Server = Server,
  connect = connect,
  listen = listen,
	new = new
}
