local scene_manager = require 'lib.conductor'
local camera        = require 'lib.camera'
local level         = require 'cls.level.level'
local base_scene    = require 'scn._base'

local scene = {}
setmetatable(scene, base_scene)
scene.__index = scene

local MAX_PARTY_SIZE = 4
local INPUT_DELAY = 0.2

-- TODO: Remove this when skins have been implemented. Currently just uses colours
local SKINS = {
    {94/255, 76/255, 90/255},
    {85/255, 145/255, 127/255},
    {127/255, 126/255, 255/255},
    {229/255, 232/255, 182/255},
    {227/255, 23/255, 10/255},
}

function scene.new()
    local self = base_scene.new("Title")
    setmetatable(self, scene)

    self.available_character_classes = {"Knight", "Ranger", "Wizard"}
    self.controllers = {}
    self.party = {}
    self.all_ready = false

    -- TODO: Add a title graphic and maybe some background animations?
    return self
end

function scene:gamepadPressed(gamepad, key)
    if not self.controllers[gamepad] then
        local player = {
            gamepad = gamepad,
            input_delay = 0,
            ready = false,
            class_id = 1,
            skin_id = 1,
        }
        table.insert(self.party, player)
        self.controllers[gamepad] = #self.party
        self.all_ready = false
        return
    end

    local player = self.party[self.controllers[gamepad]]
    if not player then return end

    if player.input_delay > 0 then return end

    if self.all_ready and key == "a" then
        local next_scene = require('scn.level').new()
        scene_manager.setScene(next_scene)
    end

    if player.ready and key ~= "b" then return end

    if player.ready and key == "b" then
        player.ready = false
        self.all_ready = false
    end

    if key == "a" then
        player.ready = true
        self.all_ready = true
        for _, p in pairs(self.party) do
            if not p.ready then 
                self.all_ready = false
            end
        end
    end

    if key == "dpright" then
        player.class_id = player.class_id + 1
        if player.class_id > #self.available_character_classes then
            player.class_id = 1
        end
    end
    if key == "dpleft" then
        player.class_id = player.class_id - 1
        if player.class_id < 1 then
            player.class_id = #self.available_character_classes
        end
    end
    if key == "rightshoulder" then
        player.skin_id = player.skin_id + 1
        if player.skin_id > #SKINS then
            player.skin_id = 1
        end
    end
    if key == "leftshoulder" then
        player.skin_id = player.skin_id - 1
        if player.skin_id < 1 then
            player.skin_id = #SKINS
        end
    end
    player.input_delay = INPUT_DELAY
end

function scene:gamepadAxis(gamepad, axis, value)
    local player = self.party[self.controllers[gamepad]]
    if not player then return end

    if player.ready then return end

    local EPSILON = 0.1
    if axis == "leftx" and player.input_delay == 0 then
        if value > 0.5 then
            player.class_id = player.class_id + 1
            if player.class_id > #self.available_character_classes then
                player.class_id = 1
            end
            player.input_delay = INPUT_DELAY
        elseif value < -0.5 then
            player.class_id = player.class_id - 1
            if player.class_id < 1 then
                player.class_id = #self.available_character_classes
            end
            player.input_delay = INPUT_DELAY
        end
    end
end

function scene:gamepadRemoved(gamepad)
    local index = self.controllers[gamepad]
    if index then
        table.remove(self.party, index)
    end
end

function scene:gamepadAdded(gamepad)
    if self.controllers[gamepad] then
        table.insert(self.party, gamepad)
        self.controllers[gamepad] = #self.party
    end
end

function scene:update(dt)
    for _, player in pairs(self.party) do
        player.input_delay = player.input_delay - dt
        if player.input_delay < 0 then
            player.input_delay = 0
        end
    end
end

function scene:draw()
    for i, player in pairs(self.party) do
        local x = 24 + (i-1) * 128
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", x, 24, 128, 256)
        love.graphics.printf(self.available_character_classes[player.class_id], x, 32, 128, "center")
        love.graphics.setColor(SKINS[player.skin_id])
        love.graphics.rectangle("fill", x + 4, 64, 120, 3)
        if player.ready then
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("READY", x, 192, 128, "center")
        end
    end
    if self.all_ready then
        love.graphics.printf("READY", 0, love.graphics.getHeight() - 32, love.graphics.getWidth(), "center")
    end
end

return scene