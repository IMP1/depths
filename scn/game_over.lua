local scene_manager = require 'lib.conductor'
local camera        = require 'lib.camera'
local level         = require 'cls.level.level'
local base_scene    = require 'scn._base'

local scene = {}
setmetatable(scene, base_scene)
scene.__index = scene

local fonts = {}
fonts.system = love.graphics.newFont("res/fonts/Cormorant-Regular.ttf", 20)
fonts.title = love.graphics.newFont("res/fonts/Cormorant-Light.ttf", 48)

local BGM = love.audio.newSource("res/music/From Here.ogg", "stream")

function scene.new(party, level)
    local self = base_scene.new("Game Over")
    setmetatable(self, scene)

    self.party = party
    self.level = level

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
    love.graphics.setFont(fonts.title)
    love.graphics.printf("Game Over", 0, 100, love.graphics.getWidth(), "center")
    
end

return scene