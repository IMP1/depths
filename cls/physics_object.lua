local level = require 'cls.level.level'
local vec2 = require 'lib.vec2'

local physics_object = {}
physics_object.__index = physics_object

function physics_object.new(x, y, radius, mass)
    local self = {}
    setmetatable(self, physics_object)

    self.position = vec2(x, y)
    self.radius = radius
    self.mass = mass

    return self
end

function physics_object:tile_position()
    local x, y = unpack((self.position / level.TILE_SIZE).data)
    return math.floor(x) + 1, math.floor(y) + 1
end

function physics_object:is_at_tile(x, y)
    local ox, oy = self:tile_position()
    return x == ox and y == oy
end

function physics_object:is_at_pixel(x, y, leeway)
    local difference = vec2(x, y) - self.position
    return difference:magnitudeSquared() < (leeway or self.radius) ^ 2
end

return physics_object