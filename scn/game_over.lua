local scene_manager = require 'lib.conductor'
local base_scene    = require 'scn._base'

local scene = {}
setmetatable(scene, base_scene)
scene.__index = scene

local fonts = {}
fonts.system = love.graphics.newFont("res/fonts/Cormorant-Regular.ttf", 20)
fonts.title = love.graphics.newFont("res/fonts/Cormorant-Light.ttf", 48)

local TEXT_COLOUR = {229/255, 232/255, 182/255}

local BGM = love.audio.newSource("res/music/From Here.ogg", "stream")

function scene.new(party, level)
    local self = base_scene.new("Game Over")
    setmetatable(self, scene)

    self.party = party
    self.level = level

    -- TODO: Work out stats (level reached, kills, causes of death, etc.)

    -- TODO: Add a title graphic and maybe some background animations?
    return self
end

function scene:load(...)
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    BGM:play()
end

function scene:keyPressed(key)
    
end

function scene:gamepadPressed(gamepad, key)
    if key == "start" then
        local title_scene = require('scn.title').new()
        scene_manager.pushScene(title_scene) 
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

function scene:draw()
    -- TODO: Draw some stats (level reached, kills, causes of death, etc.)
    love.graphics.setColor(TEXT_COLOUR)
    love.graphics.setFont(fonts.title)
    love.graphics.printf(T"Game Over", 0, 100, love.graphics.getWidth(), "center")
    love.graphics.setFont(fonts.system)
    love.graphics.printf(T"Press START to continue to the title screen.", 0, love.graphics.getHeight() - 80, love.graphics.getWidth(), "center")
    
end

return scene