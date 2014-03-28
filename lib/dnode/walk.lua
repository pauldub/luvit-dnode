local Object = require('core').Object

local table = require('table')

local Queue = require('./queue')

local Logger = require('./logger')
local logger = Logger:new('walk')

local Node = Object:extend()

function Node:initialize(params)
  self.value = params.value
  self.path = params.path
end

local Walk = Object:extend()

function Walk:initialize(obj)
	self.logger = logger
  self.path = {} 
	self.obj = obj
  self.fns = { test = function() end }
end

function Walk:clone(obj)
  self:_walk(obj, function(node)
    if type(obj) ~= 'table' then
      node.value = node.value 
    end
  end)
end

function Walk:walk(cb)
  return self:_walk(self.obj, cb) 
end

local function copy_table(t)
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = v
  end
  return copy
end

function Walk:_walk(obj, cb)
  local node = Node:new({ value = obj, path = self.path })

  cb(node) 

  local value = node.value 
  local value_type = type(value)

  logger.debug('value', value, value_type)
  logger.debug('value', node)
    
  if value_type == 'table' then
    local copy = { }
    local acc = 0
    for k,v in pairs(value) do
      if v ~= nil then 
      self.path[#self.path + 1] = k
      local walk_val = self:_walk(v, cb)
        copy[k] = walk_val
      self.path[#self.path] = nil
      end
    end
    return copy
  elseif value_type == 'boolean' or value_type == 'string' or value_type == 'number' or value_type == 'function' then
    return value
  else
    error('' .. value_type .. 'not handled')
  end
end

return Walk

