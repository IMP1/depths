local level = {}
level.__index = level

local tile = {
    NONE        = 0,
    FLOOR       = 1,
    FLOOR_START = 2,
    FLOOR_END   = 3,
    FLOOR_BOSS  = 4,
    WALL_TOP    = 5,
    WALL_SIDE   = 6,
    FAKE_WALL   = 7,
    FLOOR_DEBUG = 8,
    WALL_DEBUG  = 9,
}

level.tile = tile

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

    return self
end

function level:refresh_auto_tiles()
end

function level:draw()
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
            elseif t == tile.WALL_TOP then
                love.graphics.setColor(0.4, 0.4, 0.4)
            elseif t == tile.WALL_SIDE then
                love.graphics.setColor(0.3, 0.3, 0.3)
            elseif t == tile.WALL_DEBUG then
                love.graphics.setColor(0.4, 0.4, 0.2)
            elseif t == tile.FLOOR_DEBUG then
                love.graphics.setColor(0.8, 0.8, 0.5)
            else 
                love.graphics.setColor(1, 0, 0)
            end
            local s = 1
            love.graphics.rectangle("fill", (i-1) * s, (j-1) * s, s, s)
        end
    end
end

return level
