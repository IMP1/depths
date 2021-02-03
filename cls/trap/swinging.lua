local trap = require 'cls.trap._base'
local animation = require 'lib.animation'
local vec2 = require 'lib.vec2'

local swinging_trap = {}
setmetatable(swinging_trap, trap)
swinging_trap.__index = swinging_trap

swinging_trap.DAMAGE = 50

function swinging_trap.new(x, y, direction)
    local self = trap.new(x, y, "Swinging")
    setmetatable(self, swinging_trap)

    self.direction = direction

    return self
end

function swinging_trap:draw()
    -- TODO: Draw a pressure plate
end

function swinging_trap:trigger()
end

return swinging_trap