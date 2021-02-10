local enemy = require 'cls.enemy._base'

local laarl = {}
setmetatable(laarl, enemy)
laarl.__index = laarl

local RADIUS = 4
local MASS   = 20
local HEALTH = 50
local SPEED  = 130

function laarl.new(x, y, direction)
    local self = enemy.new(name, x, y, direction, RADIUS, MASS, HEALTH, SPEED)
    setmetatable(self, laarl)

    self.jump_cooldown = 0

    return self
end

function laarl:draw(scene)
    local x, y = unpack(self.position.data)
    love.graphics.setColor(0.1, 0.3, 0.2)
    love.graphics.circle("line", x, y, self.radius)
end

return laarl