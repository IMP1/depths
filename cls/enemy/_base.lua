local vec2  = require 'lib.vec2'
local actor = require 'cls.actor'

local enemy = {}
setmetatable(enemy, actor)
enemy.__index = enemy

function enemy.new(name, x, y, direction, radius, mass, health, speed)
    local self = actor.new(name, x, y, direction, radius, mass, health)
    setmetatable(self, enemy)

    self.speed = speed

    return self
end

return enemy