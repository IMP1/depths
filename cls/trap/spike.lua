local animation = require 'lib.animation'
local vec2      = require 'lib.vec2'
local level     = require 'cls.level.level'
local trap      = require 'cls.trap._base'

local spike_trap = {}
setmetatable(spike_trap, trap)
spike_trap.__index = spike_trap

local IMAGE_PATH = "res/traps/spike.png"
local FRAME_DURATIONS = {0.04, 0.08, 0.16, 1, 0.1, 0.1, 0.5}
local DAMAGE_FRAME = 4

spike_trap.DAMAGE = 50

function spike_trap.new(x, y)
    local self = trap.new(x, y, "Spike", 1, 400)
    setmetatable(self, spike_trap)

    self.animation = nil
    if love.graphics then
        self.animation = animation.new({
            image = love.graphics.newImage(IMAGE_PATH),
            frames = 7,
            frames_wide = 7,
            frames_high = 1,
            loop = false,
            frame_durations = FRAME_DURATIONS,
        })
    end
    self.hit = false

    return self
end

function spike_trap:trigger(scene)
    if not self.animation:is_playing() then
        self.animation:reset()
        self.animation:start()
        self.hit = false
        self.triggered = true
    end
end

function spike_trap:update(dt, scene)
    trap.update(self, dt, scene)
    if self.animation and self.animation:is_playing() then
        self.animation:update(dt)
        if self.animation.current_frame == DAMAGE_FRAME and not self.hit then
            self.hit = true
            local x, y = unpack(((self.trigger_position - vec2(1, 1)) * level.TILE_SIZE).data)
            local obj = scene:get_object_at(x, y, 8, self)
            if obj and obj.damage then
                obj:damage(spike_trap.DAMAGE)
            end
        end
        if self.animation.finished then
            self.triggered = false
        end
    end
end

function spike_trap:draw(scene)
    love.graphics.setColor(1, 1, 1)
    local i, j = unpack(self.trigger_position.data)
    if scene.visited[j][i] then
        local x, y = unpack(((self.trigger_position - vec2(1, 1)) * level.TILE_SIZE).data)
        if scene.visible[j][i] then
            self.animation:draw(x, y)
        else
            love.graphics.draw(self.animation.image, self.animation.quads[1], x, y)
        end
    end
end

return spike_trap
