local animation = require 'lib.animation'
local vec2      = require 'lib.vec2'
local trap      = require 'cls.trap._base'
local level     = require 'cls.level.level'
local boulder   = require 'cls.projectile.boulder'

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

    local boulder_direction = (self.trigger_position - self.boulder_position):normalise()
    local x, y = unpack(((self.boulder_position - vec2(0.5, 0.5)) * level.TILE_SIZE).data)
    local b = boulder.new(x, y, boulder_direction.x, boulder_direction.y)
    table.insert(scene.projectiles, b)
end

function boulder_trap:is_at_tile(i, j)
    local x1, y1 = unpack(self.trigger_position.data)
    local x2, y2 = unpack(self.boulder_position.data)
    return i >= math.min(x1, x2) and i <= math.max(x1, x2) and
           j >= math.min(y1, y2) and j <= math.max(y1, y2)
end

function boulder_trap:draw(scene)
    do
        local i, j = unpack(self.trigger_position.data)
        if scene.visited[j][i] then
            local x, y = (i-1) * level.TILE_SIZE, (j-1) * level.TILE_SIZE
            love.graphics.setColor(0, 0, 1, 0.8)
            love.graphics.rectangle("fill", x + 4, y + 4, level.TILE_SIZE - 8, level.TILE_SIZE - 8)
        end
    end
    do
        local i, j = unpack(self.boulder_position.data)
        if scene.visited[j][i] then
            local boulder_direction = (self.trigger_position - self.boulder_position):normalise()
            local x, y = unpack(((self.boulder_position - vec2(0.5, 0.5)) * level.TILE_SIZE).data)
            love.graphics.setColor(0, 0, 1, 0.8)
            love.graphics.circle("fill", x, y, level.TILE_SIZE / 4)
        end
    end
end

return boulder_trap