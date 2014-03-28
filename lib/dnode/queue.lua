local core = require('core')

local Queue = core.Object:extend()
function Queue:initialize(initial_list)
  self.first = 1
  self.last = 0 
  self.list = initial_list or { }
end

function Queue:lpush(value)
  local first = self.first - 1
  self.first = first
  self.list[first] = value
end

function Queue:rpush(value)
  local last = self.last + 1
  self.last = last
  self.list[last] = value
end

function Queue:lpop(value)
  local first = self.first
  if first > self.last then
    error('list is empty')
  end 
  local value = self.list[first]
  self.list[first] = nil
  self.first = first + 1
  return value
end

function Queue:rpop(value)
  local last = self.last
  if self.first > last then
    error('list is empty')
  end 
  local value = self.list[last]
  self.list[last] = nil
  self.last = last - 1
  return value
end

return Queue
