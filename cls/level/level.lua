local level = {}
level.__index = level

local floor_type = {
    CAVES = 1,
    -- TODO: Think of more floor types? Steal Vagente's?
}

local tile = {
    NONE        = 0,
    FLOOR       = 1,
    FLOOR_START = 2,
    FLOOR_END   = 3,
    FLOOR_BOSS  = 4,
    FLOOR_HALL  = 5,
    WALL_TOP    = 6,
    WALL_SIDE   = 7,
    COLUMN_TOP  = 6,
    COLUMN_SIDE = 7,
    FAKE_WALL   = 8,
}

level.TILE_SIZE = 16

level.tiles = tile
level.floor_types = floor_type

function level.generate(options)
    local thread = love.thread.newThread("cls/level/generator.lua")
    love.thread.getChannel("level-gen"):clear()
    thread:start()
    love.thread.getChannel("level-gen"):supply(options)
    return thread
end

function level.new(options)
    local self = {}
    setmetatable(self, level)

    self.tiles = options.tiles
    self.seed = options.seed
    self.rooms = options.rooms -- Shouldn't be needed outside of level generation (and its testing). TODO: Remove when finished
    self.connections = options.connections -- Shouldn't be needed outside of level generation (and its testing). TODO: Remove when finished
    self.start_position = options.start_position
    self.end_position = options.end_position
    self.boss_position = options.boss_position
    self.auto_tiles = options.auto_tiles
    self.fake_walls = options.fake_walls
    self.traps = options.traps
    self.enemies = options.enemies
    self.treasure = options.treasure

    return self
end

function level:refresh_auto_tiles()
end

function level:draw(tile_size)
    local s = tile_size or 1
    for j, row in pairs(self.tiles) do
        for i, t in pairs(row) do
            if t == tile.NONE then
                love.graphics.setColor(0, 0, 0)
            elseif t == tile.FLOOR then
                love.graphics.setColor(0.6, 0.6, 0.6)
            elseif t == tile.FLOOR_START then
                love.graphics.setColor(0.5, 0.8, 0.5)
            elseif t == tile.FLOOR_END then
                love.graphics.setColor(0.8, 0.5, 0.4)
            elseif t == tile.FLOOR_BOSS then
                love.graphics.setColor(0.5, 0.5, 0.8)
            elseif t == tile.FLOOR_HALL then
                love.graphics.setColor(0.6, 0.6, 0.6)
            elseif t == tile.WALL_TOP then
                love.graphics.setColor(0.4, 0.4, 0.4)
            elseif t == tile.WALL_SIDE then
                love.graphics.setColor(0.3, 0.3, 0.3)
            elseif t == tile.FAKE_WALL then
                love.graphics.setColor(0.4, 0.2, 0.2)
            else 
                love.graphics.setColor(1, 0, 0)
            end
            love.graphics.rectangle("fill", (i-1) * s, (j-1) * s, s, s)
        end
    end
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("line", (self.start_position.x - 1) * s, (self.start_position.y - 1) * s, s, s)
    love.graphics.rectangle("line", (self.end_position.x - 1) * s, (self.end_position.y - 1) * s, s, s)

    for _, trap in pairs(self.traps) do
        local x, y = unpack(trap.trigger_position.data)
        love.graphics.setColor(1, 0, 0, 0.4)
        love.graphics.rectangle("fill", (x-1)*s, (y-1)*s, s, s)
        if love.keyboard.isDown("t") then
            if trap.boulder_position then
                local bx, by = unpack(trap.boulder_position.data)
                love.graphics.setColor(1, 0, 0, 0.4)
                love.graphics.rectangle("fill", (bx-1)*s, (by-1)*s, s, s)
                love.graphics.line((x-0.5)*s, (y-0.5)*s, (bx-0.5)*s, (by-0.5)*s)
            end
            if trap.arrow_position then
                local ax, ay = unpack(trap.arrow_position.data)
                love.graphics.setColor(1, 0, 0, 0.4)
                love.graphics.rectangle("fill", (ax-1)*s, (ay-1)*s, s, s)
                love.graphics.line((x-0.5)*s, (y-0.5)*s, (ax-0.5)*s, (ay-0.5)*s)
            end
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(trap.name, (x-1)*s, (y-1)*s)
        end
    end
end

return level
