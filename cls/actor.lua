local object = require 'cls.destroyable_object'

local actor = {}
setmetatable(actor, object)
actor.__index = actor

function actor.new(name, x, y, direction, radius, mass, health)
    local self = object.new(x, y, radius, mass, health)
    setmetatable(self, actor)

    self.name = name
    self.direction = direction
    self.view_distance = 6 -- tiles
    self.visibility = {}

    return self
end

function actor:update_visibility()
    -- TODO: Do this
end

return actor