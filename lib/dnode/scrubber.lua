local Emitter = require('core').Emitter

local table = require('table')
local Queue = require('./queue')
local Walk = require('./walk')
local copy_table = require('./utils').copy_table

local Logger = require('./logger')
local logger = Logger:new('scrubber')

local Scrubber = Emitter:extend()
function Scrubber:initialize(callbacks)
	self.logger = logger
  self.callbacks = Queue:new(callbacks)
end

function Scrubber:scrub(obj)
  local paths = {}
  local links = {}
  local walker = Walk:new(obj)

  local walked = walker:walk(function(node)
    logger.debug('scrub node:', node.value, 'type:', type(node.value))
    if type(node.value) == 'function' then
      self.callbacks:rpush(node.value) 
      local id = self.callbacks.last 

      logger.debug('scrub node id:', id, 'path:', node.path)
      for k,v in pairs(node.path) do logger.debug('node.path:', { key = k, value = v }) end

      paths[id] = copy_table(node.path)

      node.value = '[Function]'
    end
  end)
  logger.debug('scrub walked', walked) 
  logger.debug('scrub walked', paths) 
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
  logger.debug('unscrub msg', msg and msg.arguments)
  local walker = Walk:new(msg and msg.arguments or {})
  local args = walker:walk(function(node)
    local path = node and node.path or {}
    logger.debug('unscrub node:', node)
    logger.debug('unscrub path:', path)
    -- local pair =
    local id
    for k,v in pairs(msg and msg.callbacks or {}) do
      if path_equal(v, path) then
        id = k
        logger.debug('scrubber path id', id)
        node.value = f(id)
      end 
    end 
  end)
  logger.debug(args)
  return args
end

return Scrubber
