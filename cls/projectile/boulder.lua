local projectile = require 'cls.projectile._base'

local boulder = {}
setmetatable(boulder, projectile)
boulder.__index = boulder

local SPEED = 256
local RADIUS = 16
local MASS = 600
local DAMAGE = 9999
local MIN_MASS_TO_DESTROY = 500

function boulder.new(x, y, dx, dy)
    local self = projectile.new(x, y, dx * SPEED, dy * SPEED, RADIUS, MASS, DAMAGE)
    setmetatale(self, boulder)

    return self
end

function boulder:hit(obj)
    -- Don't destroy boulder on small squishy things
    if obj then
        obj:damage(max_damage)
        if obj.mass > MIN_MASS_TO_DESTROY then
            self:destroy()
        end
    else
        self:destroy()
    end
end

function boulder:destroy()
    projectile.destroy(self)
    -- TODO: Remove screenshake rumble
end

function boulder:update(dt, scene)
    self.animation:update(dt)
end

return boulder