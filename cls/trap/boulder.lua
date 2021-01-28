local trap = require 'cls.trap._base'
local animation = require 'lib.animation'
local vec2 = require 'lib.vec2'
local boulder = require 'cls.projectile.boulder'

local boulder_trap = {}
setmetatable(boulder_trap, trap)
boulder_trap.__index = boulder_trap

-- local IMAGE = love.graphics.newImage("res/trap/boulder_trap.png")

function boulder_trap.new(trigger_x, trigger_y, boulder_x, boulder_y)
    local self = trap.new(trigger_x, trigger_y, "Boulder", 1)
    setmetatable(self, boulder_trap)

    self.boulder_position = vec2(boulder_x, boulder_y)

    return self
end

function boulder_trap:trigger(scene)
    if self.triggered then return end
    self.triggered = true

    -- TODO: Add boulder to scene
end

function boulder_trap:is_at_tile(i, j)
    local x1, y1 = unpack(self.trigger_position.data)
    local x2, y2 = unpack(self.boulder_position.data)
    return i >= math.min(x1, x2) and i <= math.max(x1, x2) and
           j >= math.min(y1, y2) and j <= math.max(y1, y2)
end

function boulder_trap:draw()
    -- TODO: Draw a pressure plate
end

return boulder_trap