local animation = require 'lib.animation'
local vec2      = require 'lib.vec2'
local level     = require 'cls.level.level'
local trap      = require 'cls.trap._base'
local arrow     = require 'cls.projectile.arrow'

local arrow_trap = {}
setmetatable(arrow_trap, trap)
arrow_trap.__index = arrow_trap

local FIRE_DELAY = 0.5 -- seconds

function arrow_trap.new(trigger_x, trigger_y, arrow_x, arrow_y, ammo)
    local self = trap.new(trigger_x, trigger_y, "Arrow", 1)
    setmetatable(self, arrow_trap)

    self.arrow_position = vec2(arrow_x, arrow_y)
    self.ammo = ammo or 10
    self.fire_delay = 0

    return self
end

function arrow_trap:trigger(scene)
    if self.fire_delay > 0 then return end
    if self.ammo then
        if self.ammo <= 0 then return end
        self.ammo = self.ammo - 1
    end 
    self.triggered = true
    local arrow_direction = (self.trigger_position - self.arrow_position):normalise()
    local x, y = unpack(((self.arrow_position - vec2(0.5, 0.5) + arrow_direction * 0.5) * level.TILE_SIZE).data)
    local a = arrow.new(x, y, arrow_direction.x, arrow_direction.y)
    table.insert(scene.projectiles, a)
    self.fire_delay = FIRE_DELAY
end

function arrow_trap:is_at_tile(i, j)
    local x1, y1 = unpack(self.trigger_position.data)
    local x2, y2 = unpack(self.arrow_position.data)
    return i >= math.min(x1, x2) and i <= math.max(x1, x2) and
           j >= math.min(y1, y2) and j <= math.max(y1, y2)
end

function arrow_trap:update(dt, ...)
    trap.update(self, dt, ...)
    if self.fire_delay > 0 then
        self.fire_delay = math.max(0, self.fire_delay - dt)
    end
end

function arrow_trap:draw(scene)
    do
        -- Draw a pressure plate if visited
        local i, j = unpack(self.trigger_position.data)
        if scene.visited[j][i] then
            local x, y = (i-1) * level.TILE_SIZE, (j-1) * level.TILE_SIZE
            love.graphics.setColor(1, 0, 0, 0.8)
            love.graphics.rectangle("fill", x + 4, y + 4, level.TILE_SIZE - 8, level.TILE_SIZE - 8)
        end
    end
    do
        -- Draw a arrow shooty hole if visited
        local i, j = unpack(self.arrow_position.data)
        if scene.visited[j][i] then
            local x, y = (i-0.5) * level.TILE_SIZE, (j-0.5) * level.TILE_SIZE
            love.graphics.setColor(1, 0, 0, 0.8)
            love.graphics.circle("fill", x, y, level.TILE_SIZE / 4)
        end
    end
end

return arrow_trap