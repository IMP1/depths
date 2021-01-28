local object = require 'cls.physics_object'

local destroyable_object = {}
setmetatable(destroyable_object, object)
destroyable_object.__index = destroyable_object

function destroyable_object.get_health_colour(health)
    local r = 2 * (1 - health)
    local g = 2 * health
    if r > 1 then r = 1 end
    if g > 1 then g = 1 end
    return {r, g, 0}
end

function destroyable_object.new(x, y, radius, mass, health)
    local self = object.new(x, y, radius, mass)
    setmetatable(self, destroyable_object)

    self.max_health = health
    self.current_health = max_health
    self.destroyed = false

    return self
end

function destroyable_object:damage(amount)
    if self.destroyed then return end
    self.current_health = self.current_health - amount
    if self.current_health <= 0 then
        self:destroy()
    end
    if self.current_health > self.max_health then
        self.current_health = self.max_health
    end
    -- TODO: Add popup to scene? Maybe whatever calls this handles that
end

function destroyable_object:heal(amount, can_restore)
    if self.destroyed and can_restore and amount > 0 then
        self.destroyed = false
        self:damage(-amount)
    elseif not self.destroyed then
        self:damage(-amount)
    end
end

function destroyable_object:destroy()
    self.current_health = 0
    self.destroyed = true
end

return destroyable_object