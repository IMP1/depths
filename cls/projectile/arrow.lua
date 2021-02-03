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
    setmetatale(self, arrow)

    return self
end

function arrow:destroy()
    projectile.destroy(self)
end

function arrow:update(dt, scene)
    self.animation:update(dt)
end

return arrow