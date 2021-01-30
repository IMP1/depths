local scene_manager = require 'lib.conductor'
local camera        = require 'lib.camera'
local level         = require 'cls.level.level'
local base_scene    = require 'scn._base'

local scene = {}
setmetatable(scene, base_scene)
scene.__index = scene

function scene.new()
    local self = base_scene.new("Title")
    setmetatable(self, scene)

    self.party = {}

    -- TODO: Add a title graphic and maybe some background animations?
    return self
end

function scene:keyPressed(key)
end

function scene:update(dt)
end

function scene:draw()
end

return scene