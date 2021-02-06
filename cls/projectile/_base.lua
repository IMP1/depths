local vec2 = require 'lib.vec2'
local physics_object = require 'cls.physics_object'

local projectile = {}
setmetatable(projectile, physics_object)
projectile.__index = projectile

function projectile.new(x, y, vx, vy, radius, mass, damage)
    local self = physics_object.new(x, y, radius, mass)
    setmetatable(self, projectile)

    self.velocity = vec2(vx, vy)
    self.speed = self.velocity:magnitude()
    self.destroyed = false
    self.max_damage = damage

    return self
end

function projectile:hit(obj)
    if obj and obj.damage then
        obj:damage(self.max_damage)
    end
    self:destroy()
end

function projectile:destroy()
    self.destroyed = true
end

function projectile:can_move_through(old_position, new_position, scene)
    local passable, obstruction = scene:is_pixel_passable(new_position.x, new_position.y, self)
    if not passable then
        return false, obstruction
    end
    local midpoint = (old_position + new_position) / 2
    passable, obstruction = scene:is_pixel_passable(midpoint.x, midpoint.y, self)
    if not passable then
        return false, obstruction
    end
    return true
    -- TODO: Check along the way? For large values of dt
end

function projectile:update(dt, scene)
    if self.destroyed then return end
    local new_pos = self.position + self.velocity * dt
    local passable, obstruction = self:can_move_through(self.position, new_pos, scene)
    if passable then
        self.position = new_pos
    else
        local x, y = unpack(((new_pos + self.position) / 2).data)
        local collider = scene:get_object_at(x, y, self.radius, self)
        self:hit(collider)
    end
end

function projectile:draw()
    error("`draw` not implemented in projectile subclass.")
end

return projectile
