local vec2      = require 'lib.vec2'
local animation = require 'lib.animation'
local level     = require 'cls.level.level'
local trap      = require 'cls.trap._base'

local swinging_trap = {}
setmetatable(swinging_trap, trap)
swinging_trap.__index = swinging_trap

local IMAGE_PATH_VERT = "res/traps/swing_vert.png"
local IMAGE_PATH_HORZ = "res/traps/swing_horz.png"
local DAMAGE_FRAME = 3

swinging_trap.DAMAGE = 50

function swinging_trap.new(x, y, direction)
    local self = trap.new(x, y, "Swinging")
    setmetatable(self, swinging_trap)

    self.direction = direction
    if love.graphics then
        local image_path
        if self.direction == 0 then
            image_path = IMAGE_PATH_HORZ
        else
            image_path = IMAGE_PATH_VERT
        end
        self.animation = animation.new({
            image = love.graphics.newImage(image_path),
            frames = 4,
            frames_wide = 4,
            frames_high = 1,
            loop = true,
            frame_durations = 0.2,
        })
        self.animation:start()
    end

    return self
end

function swinging_trap:update(dt, scene)
    if self.animation and self.animation:is_playing() then
        self.animation:update(dt)
        if self.animation.current_frame == DAMAGE_FRAME and not self.hit then
            self.hit = true
            local x, y = unpack(((self.trigger_position - vec2(1, 1)) * level.TILE_SIZE).data)
            local obj = scene:get_object_at(x, y, 8, self)
            if obj and obj.damage then
                obj:damage(swinging_trap.DAMAGE)
            end
        elseif self.animation.current_frame ~= DAMAGE_FRAME and self.hit then
            self.hit = false
        end
    end
end

function swinging_trap:draw(scene)
    do -- DEBUG draw
        local x, y = unpack(((self.trigger_position - vec2(0.5, 0.5)) * level.TILE_SIZE).data)
        love.graphics.setColor(0, 1, 0, 0.5)
        if self.direction == 0 then
            love.graphics.rectangle("line", x-8, y-2, 16, 4)
        else
            love.graphics.rectangle("line", x-2, y-8, 4, 16)
        end
    end
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

return swinging_trap