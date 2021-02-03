local actor = require 'cls.actor'

local player = {}
setmetatable(player, actor)
player.__index = player

function player.new(x, y, direction, class, skin)
    local name = ""
    local radius = 8
    local mass = 80
    local health = 100
    -- TODO: Get above values from class
    local self = actor.new(name, x, y, direction, radius, mass, health)
    setmetatable(self, player)

    return self
end

function player:draw()
    love.graphics.setColor(1, 1, 1)
    local x, y = unpack(self.position.data)
    local x2 = x + self.radius * math.cos(self.direction)
    local y2 = y + self.radius * math.sin(self.direction)
    love.graphics.circle("line", x, y, self.radius)
    love.graphics.line(x, y, x2, y2)
    -- TODO: Draw a shape that indicates position and direction
end

return player