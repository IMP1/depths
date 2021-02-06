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

function arrow:draw(scene)
    if self.destroyed then return end
    local length = self.radius * 2
    local i, j = self:tile_position()
    if scene.visible[j][i] then
        local x, y = unpack(self.position.data)
        local x2, y2 = unpack((self.position + self.velocity:normalise() * length).data)
        love.graphics.setColor(1, 1, 1)
        love.graphics.line(x, y, x2, y2)
    end
end

return arrow
