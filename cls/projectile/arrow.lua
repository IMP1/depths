local projectile = require 'cls.projectile._base'

local arrow = {}
setmetatable(arrow, projectile)
arrow.__index = arrow

local SPEED = 512
local DAMAGE = 10
local RADIUS = 4
local MASS = 0 -- flying, innit

function arrow.new(x, y, dx, dy)
    local self = projectile.new(x, y, dx * SPEED, dy * SPEED, RADIUS, MASS, DAMAGE)
    setmetatable(self, arrow)

    return self
end

function arrow:draw()
    if self.destroyed then return end
    love.graphics.setColor(1, 1, 1)
    local length = 4
    local x, y = unpack(self.position.data)
    local x2, y2 = unpack((self.position + self.velocity:normalise() * length).data)
    love.graphics.line(x, y, x2, y2)
end

return arrow
