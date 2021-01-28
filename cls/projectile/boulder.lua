local projectile = require 'cls.projectile._base'

local boulder = {}
setmetatable(boulder, projectile)
boulder.__index = boulder

local SPEED = 256

function boulder.new(x, y, dx, dy)
    local self = projectile.new(x, y, dx * SPEED, dy * SPEED, 16, 600, 9999)
    setmetatale(self, boulder)

    return self
end

function boulder:destroy()
    projectile.destroy(self)
end

function boulder:update(dt, scene)
    self.animation:update(dt)
end

return boulder