local iStream = require('core').iStream
local dump = require('utils').dump

local default_log_levels = {
	'debug', 'info', 'warn', 'error', 'fail'
}

local default_log_level = 'info'

local StdOut = iStream:extend()
function StdOut:write(data)
	print(data)
end

local Logger = iStream:extend()

function Logger:initialize(name, opts)
	local options = opts or {}

	self.name = name
	self.levels = options.levels or default_log_levels
	self.level = options.level or default_log_level
	self.out = options.out or StdOut:new()

	for k,level in pairs(self.levels) do
		self[level] = function(...)
			self:emit('log', self, level, ...)
		end
	end

	self:on('log', self.log)	
	self:pipe(self.out)
end

function Logger:levelIndex(level) 
	if type(level) == 'number' then
		return level
	end
	if level == nil then
		return
	end

	local i 
	for k, l in pairs(self.levels) do
		if level == l then
			i = k
		end
	end

	if i == nil then
		error('Log level ' .. level .. ' not found.')
	end

	return i
end

function Logger:activeLevel(level)
	if type(self.level) == number then
		return self:levelIndex(level) >= self.level
	else
		return self:levelIndex(level) >= self:levelIndex(self.level)
	end
end

function Logger:log(level, msg, ...)
	if self:activeLevel(level) == false then
		return
	end

	local message
	if type(msg) == 'string' then
		message = msg
	else
		message = dump(msg)
	end

	local more = ... 
	if more then
		message = message .. ' ' .. dump(more)
	end

	self:emit('data', '[' .. level .. '] - ' .. self.name .. ' - ' .. message)
end

return Logger
