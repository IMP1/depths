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
        if obj.isAtTile(x, y) and obj.mass >= self.min_triggerable_mass and obj.mas <= self.max_triggerable_mass then
            self:trigger(game_scene)
        end
    end
end

function trap:trigger(game_scene)
    error("`trigger` not implemented for " .. self.name .. " trap.")
end

function trap:isAt(i, j)
    return vec2(i, j) == self.trigger_position
end

return trap
