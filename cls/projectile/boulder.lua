local screenshake = require 'lib.screenshake'
local projectile = require 'cls.projectile._base'

local boulder = {}
setmetatable(boulder, projectile)
boulder.__index = boulder

local SPEED = 256
local RADIUS = 8
local MASS = 600
local DAMAGE = 9999
local MIN_MASS_TO_DESTROY = 500
local ROLL_SCREENSHAKE = 1 -- pixels
local HIT_SCREENSHAKE_STRENGTH = 3 -- pixels
local HIT_SCREENSHAKE_DURATION = 0.2 -- seconds

function boulder.new(x, y, dx, dy)
    local self = projectile.new(x, y, dx * SPEED, dy * SPEED, RADIUS, MASS, DAMAGE)
    setmetatable(self, boulder)

    -- TODO: Add and handle an animation

    self.screenshake_id = screenshake.add_rumble(ROLL_SCREENSHAKE)

    return self
end

function boulder:hit(obj)
    if obj then
        obj:damage(DAMAGE)
        if obj.mass > MIN_MASS_TO_DESTROY then
            self:destroy()
        end
    else
        self:destroy()
    end
    -- screenshake.add_screenshake(HIT_SCREENSHAKE_STRENGTH, HIT_SCREENSHAKE_STRENGTH, HIT_SCREENSHAKE_DURATION)
end

function boulder:destroy()
    screenshake.remove_rumble(self.screenshake_id)
    projectile.destroy(self)
end

function boulder:update(dt, scene)
    projectile.update(self, dt, scene)
    -- self.animation:update(dt)
end

function boulder:draw(scene)
    -- if self.destroyed then return end
    local i, j = self:tile_position()
    -- if scene.visible[j][i] then
        local x, y = unpack(self.position.data)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", x, y, self.radius)
    -- end
end

return boulder