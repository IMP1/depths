local screenshake = require 'lib.screenshake'
local projectile = require 'cls.projectile._base'

local boulder = {}
setmetatable(boulder, projectile)
boulder.__index = boulder

local SPEED = 256
local RADIUS = 16
local MASS = 600
local DAMAGE = 9999
local MIN_MASS_TO_DESTROY = 500
local ROLL_SCREENSHAKE = 1 -- pixels
local HIT_SCREENSHAKE_STRENGTH = 3 -- pixels
local HIT_SCREENSHAKE_DURATION = 0.2 -- seconds

function boulder.new(x, y, dx, dy)
    local self = projectile.new(x, y, dx * SPEED, dy * SPEED, RADIUS, MASS, DAMAGE)
    setmetatale(self, boulder)

    -- TODO: Add and handle an animation

    self.screenshake_id = screenshake.add_rumble(ROLL_SCREENSHAKE)

    return self
end

function boulder:hit(obj)
    if obj then
        obj:damage(max_damage)
        if obj.mass > MIN_MASS_TO_DESTROY then
            self:destroy()
        end
    else
        self:destroy()
    end
    screenshake.add_screenshake(HIT_SCREENSHAKE_STRENGTH, HIT_SCREENSHAKE_STRENGTH, HIT_SCREENSHAKE_DURATION)
end

function boulder:destroy()
    screenshake.remove_rumble(self.screenshake_id)
    projectile.destroy(self)
end

function boulder:update(dt, scene)
    self.animation:update(dt)
end

return boulder