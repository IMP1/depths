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
    self.finished = false
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
    self.finished = true
end

function projectile:can_move_through(old_position, new_position, scene)
    return scene:is_pixel_passable(new_position.x, new_position.y)
    -- TODO: Check along the way? For large values of dt
end

function projectile:update(dt, scene)
    local new_pos = self.position + self.velocity * dt
    if self:can_move_through(self.position, new_pos, scene) then
        self.position = new_pos
    else
        local x, y = unpack(((new_pos + self.position) / 2).data)
        local collider = scene:get_object_at(x, y, self.radius * self.speed * dt * 2, self)
        self:hit(collider)
    end
end

function projectile:draw()
    error("`draw` not implemented in projectile subclass.")
end

return projectile