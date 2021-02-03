local vec2  = require 'lib.vec2'
local actor = require 'cls.actor'

local player = {}
setmetatable(player, actor)
player.__index = player

local JOYSTICK_DEADZONE = 0.1

function player.new(x, y, direction, class, skin, gamepad)
    local name = ""
    local radius = 6
    local mass = 80
    local health = 100
    -- TODO: Get above values from class
    local self = actor.new(name, x, y, direction, radius, mass, health)
    setmetatable(self, player)

    self.gamepad = gamepad
    -- TODO: Get below values from class
    self.speed = 100

    return self
end

function player:update(dt, scene)
    local move_x = self.gamepad:getGamepadAxis("leftx")
    local move_y = self.gamepad:getGamepadAxis("lefty")
    if math.abs(move_x) < JOYSTICK_DEADZONE then
        move_x = 0
    end
    if math.abs(move_y) < JOYSTICK_DEADZONE then
        move_y = 0
    end
    local velocity = vec2(move_x, move_y) * dt * self.speed
    -- TODO: Check if motion goes through anything impassable
    self.position = self.position + velocity

    local look_x = self.gamepad:getGamepadAxis("rightx")
    local look_y = self.gamepad:getGamepadAxis("righty")
    if math.abs(look_x) < JOYSTICK_DEADZONE then
        look_x = 0
    end
    if math.abs(look_y) < JOYSTICK_DEADZONE then
        look_y = 0
    end
    self.direction = math.atan2(look_y, look_x)
end

function player:draw()
    love.graphics.setColor(1, 1, 1)
    local x, y = unpack(self.position.data)
    local x2 = x + self.radius * math.cos(self.direction)
    local y2 = y + self.radius * math.sin(self.direction)
    love.graphics.circle("line", x, y, self.radius)
    love.graphics.line(x, y, x2, y2)
    -- TODO: Draw a shape that indicates position and direction
end

return player