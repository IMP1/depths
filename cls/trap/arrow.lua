local animation = require 'lib.animation'
local vec2      = require 'lib.vec2'
local trap      = require 'cls.trap._base'
local arrow     = require 'cls.projectile.arrow'

local arrow_trap = {}
setmetatable(arrow_trap, trap)
arrow_trap.__index = arrow_trap

function arrow_trap.new(trigger_x, trigger_y, arrow_x, arrow_y)
    local self = trap.new(trigger_x, trigger_y, "Arrow", 1)
    setmetatable(self, arrow_trap)

    self.arrow_position = vec2(arrow_x, arrow_y)

    return self
end

function arrow_trap:trigger(scene)
    if self.triggered then return end
    self.triggered = true

    -- TODO: Add arrow to scene
end

function arrow_trap:is_at_tile(i, j)
    local x1, y1 = unpack(self.trigger_position.data)
    local x2, y2 = unpack(self.arrow_position.data)
    return i >= math.min(x1, x2) and i <= math.max(x1, x2) and
           j >= math.min(y1, y2) and j <= math.max(y1, y2)
end

function arrow_trap:draw()
    -- TODO: Draw a pressure plate
end

return arrow_trap