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
        local i = math.floor((ox + cosine(theta) * r) / tile_size) + 1
        local j = math.floor((oy + sine(theta) * r) / tile_size) + 1
        if j >= 1 and j <= scene.map.height and i >= 1 and i <= scene.map.width then
            scene.visited[j][i] = true
            scene.visible[j][i] = true
            if scene:is_tile_opaque(i, j) then
                return
            end
        end
    end
end

function actor:update_visibility(scene)
    local theta_size = 360 / 360--(self.view_distance * 8)
    for theta = 0, 360, theta_size do
        raycast_visibility(self, scene, theta, self.visibility)
    end
end

return actor