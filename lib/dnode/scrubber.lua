local Emitter = require('core').Emitter
local fun = require('lua-functional/lua-functional')
local table = require('table')
local table = require('table')
local utils = require('utils')

local Queue = require('./queue')
local Walk = require('./walk')

local function copy_table(t)
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = v
  end
  return copy
end

local Scrubber = Emitter:extend()
function Scrubber:initialize(callbacks)
  self.callbacks = Queue:new(callbacks)
end

function Scrubber:scrub(obj)
  local paths = {}
  local links = {}
  local walker = Walk:new(obj)

  local walked = walker:walk(function(node)
    print('scruber - scrub node:', node.value, 'type:', type(node.value))
    if type(node.value) == 'function' then
      self.callbacks:rpush(node.value) 
      local id = self.callbacks.last + 1

      print('scruber - scrub node id:', id, 'path:', utils.dump(node.path))
      for k,v in pairs(node.path) do print('scruber - node.path:', k, v) end

      paths[id] = copy_table(node.path)

      node.value = '[Function]'
    end
  end)
  print('scruber - scrub walked', utils.dump(walked)) 
  print('scruber - scrub walked', utils.dump(paths)) 
  return { arguments = walked, callbacks = paths, links = links }
end

local function path_equal(p1, p2)
  if #p1 ~= #p2 then
    return false
  end
  local res = false
  for i in pairs(p1) do
    res = p1[i] == p2[i]
  end
  return res
end

function Scrubber:unscrub(msg, f)
  print('scrubber - unscrub msg', utils.dump(msg))
  local walker = Walk:new(msg and msg.arguments or {})
  local args = walker:walk(function(node)
    local path = node and node.path or {}
    print('scrubber - unscrub node:', utils.dump(node))
    print('scrubber - unscrub path:', utils.dump(path))
    -- local pair =
    print('scruber - callbacks:', utils.dump(self.callbacks))
    print('scrubber - msg.callbacks', utils.dump(msg.callbacks))
    local id
    for k,v in pairs(msg.callbacks) do
      if path_equal(v, path) then
        id = k
        print('scrubber path id', id)
        node.value = f(id)
      end 
      -- p[#p + 1] = k
    end 
  end)
  print(utils.dump(args))
  return args
end

return Scrubber
