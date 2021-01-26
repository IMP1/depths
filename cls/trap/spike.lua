local trap = require 'cls.trap._base'
local animation = require 'lib.animation'
local vec2 = require 'lib.vec2'

local spike_trap = {}
setmetatable(spike_trap, trap)
spike_trap.__index = spike_trap

local IMAGE = love.graphics.newImage("res/trap/spike_trap.png")
local FRAME_DURATIONS = {0.04, 0.08, 0.16, 1, 0.1, 0.1, 0.5}
local DAMAGE_FRAME = 4

spike_trap.DAMAGE = 50

function spike_trap.new(x, y)
    local self = trap.new(x, y, "Spike Trap", 1, 400)
    setmetatable(self, spike_trap)

    self.animation = animation.new({
        image = IMAGE,
        frames = 7,
        frames_wide = 7,
        frames_high = 1,
        loop = false,
        frame_durations = FRAME_DURATIONS,
    })
    self.hit = false

    return self
end

function spike_trap:update(dt, game)
    trap.update(dt, game)
    if self.animation:is_playing() then
        self.animation:update(dt)
        if self.animation.current_frame == DAMAGE_FRAME and not self.hit then
            self.hit = true
        end
        if self.animation.finished then
            self.triggered = false
        end
    end
end

function spike_trap:trigger(scene)
    if not self.animation:is_playing() then
        self.animation:reset()
        self.animation:start()
        self.hit = false
        self.triggered = true
    end
end

function spike_trap:draw()
    self.animation:draw(self.trigger_position.x, self.trigger_position.y)
end

return spike_trap
