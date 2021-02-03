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

function arrow:destroy()
    projectile.destroy(self)
end

function arrow:update(dt, scene)
    projectile.update(self, dt, scene)
    -- self.animation:update(dt)
end

function arrow:draw()
    love.graphics.setColor(1, 1, 1)
    local length = 4
    local x, y = unpack(self.position.data)
    love.graphics.circle("fill", x, y, 4)
end

return arrow