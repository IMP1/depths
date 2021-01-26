local vec2 = require 'lib.vec2'

local trap = {}
trap.__index = trap

function trap.new(x, y, name, min_mass, max_mass)
    local self = {}
    setmetatable(self, trap)

    self.name = name
    self.trigger_position = vec2(x, y)
    self.min_triggerable_mass = min_mass
    self.max_triggerable_mass = max_mass
    self.triggered = false

    return self
end

function trap:update(dt, game_scene)
    local x, y = unpack(self.trigger_position.data)
    for obj in game_scene.objects_with_mass do
        local at_least_min_mass = (self.min_triggerable_mass == nil) or (obj.mass >= self.min_triggerable_mass)
        local at_most_max_mass = (self.max_triggerable_mass == nil) or (obj.mass <= self.max_triggerable_mass)
        if obj.is_at_tile(x, y) and at_least_min_mass and at_most_max_mass then
            self:trigger(game_scene)
        end
    end
end

function trap:trigger(game_scene)
    error("`trigger` not implemented for " .. self.name .. " trap.")
end

function trap:is_at_tile(i, j)
    return vec2(i, j) == self.trigger_position
end

return trap
