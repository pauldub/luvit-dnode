local net = require('net')
local math = require('math')
local string = require('string')
local bind = require('utils').bind

local Server = require('./server')
local Queue = require('./queue')

local function randomId()
	local s = ''
	for i=0, 4 do
		s = s .. string.sub(string.format('%x', math.random(4000)), 2)
	end
	return s
end

local DNode = Server:extend()

function DNode:connect(port, block)
  self:on('remote', block)

  self.stream = net.createConnection(port, function()
		local socket = self.stream
		self.id = randomId()

    socket:on('error', function(err)
      self:emit('error', err)
      socket:done()
    end)  

		self:on('end', function()
      socket:done()
		end)

    socket:pipe(self)
    self:pipe(socket) 

    return self
  end)
end

function DNode:listen(port, opts)
  self.sessions = { } -- Queue:new()
  self.net = net.createServer(function(socket)
    local d = Server:new(self.cons, opts)
		d.id = randomId()
		while self.sessions[d.id] do
			d.id = randomId()
		end

    self.sessions[d.id] = d
    
    d:on('end', function()
      socket:destroy()
      self.sessions[d.id] = nil
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

--[[local function new(self, cons, opts)
	return Server:new(cons or {}, opts)
	end]]


return DNode --[[{
	Proto = require('./proto'),
	Server = Server,
  connect = connect,
  listen = listen,
	new = new
}]]
