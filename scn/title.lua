local scene_manager = require 'lib.conductor'
local camera        = require 'lib.camera'
local level         = require 'cls.level.level'
local base_scene    = require 'scn._base'

local scene = {}
setmetatable(scene, base_scene)
scene.__index = scene

local MAX_PARTY_SIZE = 4
local INPUT_DELAY = 0.2

-- TODO: Transition this into a colour palette when skins have been implemented.
local SKINS = {
    {94/255, 76/255, 90/255},
    {85/255, 145/255, 127/255},
    {127/255, 126/255, 255/255},
    {229/255, 232/255, 182/255},
    {227/255, 23/255, 10/255},
}

local fonts = {}
fonts.system = love.graphics.newFont("res/font/Cormorant-Regular.ttf", 20)
fonts.title = love.graphics.newFont("res/font/Cormorant-Light.ttf", 48)

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

function scene:load(...)
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
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
        local next_scene = require('scn.level').new(self.party, 1)
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
    love.graphics.setFont(fonts.system)
    local w = love.graphics.getWidth()
    for i, player in pairs(self.party) do
        local w = love.graphics.getWidth() / 5
        local h = 400
        local x = 24 + (i-1) * (w + 32)
        local y = love.graphics.getHeight() - h - 64
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.rectangle("line", x, y, w, h)
        love.graphics.printf(self.available_character_classes[player.class_id], x, y + 8, w, "center")
        love.graphics.setColor(SKINS[player.skin_id])
        love.graphics.rectangle("fill", x + 4, y + 40, w - 8, 3)
        if player.ready then
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", x + 1, y + 168 - 12, w - 2, 48)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(T"READY", x, y + 168, w, "center")
        end
    end

    love.graphics.setFont(fonts.title)
    love.graphics.setColor(SKINS[1])
    love.graphics.printf(T"~  Delve  ~", 0, 64, w, "center")
    love.graphics.setColor(SKINS[4])
    love.graphics.printf(T"Delve", 0, 64, w, "center")

    love.graphics.setFont(fonts.system)
    love.graphics.setColor(SKINS[4])
    if self.all_ready then
        love.graphics.printf(T"READY", 0, love.graphics.getHeight() - 32, w, "center")
    end
    if love.joystick.getJoystickCount() == 0 then
        local y = love.graphics.getHeight() / 2
        love.graphics.printf(T"This game requires controllers to play.", 0, y - 16, w, "center")
        love.graphics.printf(T"No controllers are currently recognised.", 0, y + 16, w, "center")
        love.graphics.printf(T"Plug in a controller, or check out the help page:", 0, y + 48, w, "center")
        -- love.graphics.printf(T"https://github.com/IMP1/depths/README.md#controllers", 0, y + 80, w, "center")
    elseif #self.party == 0 then
        local y = love.graphics.getHeight() - 64
        love.graphics.printf(T"Press any button on your controller to join.", 0, y - 16, w, "center")
    end
end

return scene