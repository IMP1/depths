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

local cosine = math.cos
local sine = math.sin

local function raycast_visibility(self, scene, theta, visibility)
    local ox, oy = unpack(self.position.data)
    local tile_size = require('cls.level.level').TILE_SIZE
    for r = 0, self.view_distance * tile_size do
        local i = math.floor((ox + cosine(theta) * r) / tile_size)
        local j = math.floor((oy + sine(theta) * ) / tile_size)
        -- if scene:is_tile_opaque(i, j)
        -- TODO: do
    end
end

function actor:update_visibility()
    -- TODO: Do this
    local theta_size = 360 / (self.view_distance * 8)
    for theta = 0, 360, theta_size do
        raycast_visibility(self, theta, self.visibility)
    end
end

return actor