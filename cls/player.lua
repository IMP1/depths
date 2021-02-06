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
    self.invulnerability_timer = 0
    -- TODO: Get below values from class
    self.speed = 100

    return self
end

function player:damage(...)
    if self.invulnerability_timer == 0 then
        actor.damage(self, ...)
        -- TODO: Flash white? Show (blood) animation
        -- TODO: Add invulnerability timer?
        local invulnerability_timer = 0
        self.invulnerability_timer = invulnerability_timer
    end
end

function player:destroy(...)
    actor.destroy(self, ...)
    -- TODO: Change into ghost
    -- TODO: Either create new object and change level player pointer to that?
    --       Or change graphics and stats (but keep track of normal stats/gfx for after revive)
    self.mass = 0
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
    if move_x ~= 0 or move_y ~= 0 then
        local velocity = vec2(move_x, move_y) * dt * self.speed
        local new_position = self.position + velocity
        local test_position = new_position + velocity:normalise() * self.radius
        if scene:is_pixel_passable(test_position.x, test_position.y, self) or self.destroyed then
            -- TODO: Check for polygon collision - use `lib/polygon_intersection.lua`
            -- TODO: Check if motion goes through anything impassable (for high values of dt)
            -- TODO: Check for corners?
            self.position = self.position + velocity
        end
    end

    local look_x = self.gamepad:getGamepadAxis("rightx")
    local look_y = self.gamepad:getGamepadAxis("righty")
    if math.abs(look_x) > JOYSTICK_DEADZONE or math.abs(look_y) > JOYSTICK_DEADZONE then
        self.direction = math.atan2(look_y, look_x)
    end
    if self.invulnerability_timer > 0 then
        self.invulnerability_timer = math.max(0, self.invulnerability_timer - dt)
    end
end

function player:draw()
    love.graphics.setColor(1, 1, 1)
    if self.destroyed then
        love.graphics.setColor(1, 1, 1, 0.2)
    end
    local x, y = unpack(self.position.data)
    local x2 = x + self.radius * math.cos(self.direction)
    local y2 = y + self.radius * math.sin(self.direction)
    love.graphics.circle("line", x, y, self.radius)
    love.graphics.line(x, y, x2, y2)
end

return player