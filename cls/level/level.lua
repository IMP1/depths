local level = {}
level.__index = level

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

local traps = {
    BOULDER = "boulder",
}

level.TILE_SIZE = 16

level.tiles = tile
level.traps = traps

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

    self.fake_walls = {}
    for _, fake_wall_data in pairs(options.fake_walls) do
        local fake_wall = require('cls.level.fake_wall').new(unpack(fake_wall_data))
        table.insert(self.fake_walls, fake_wall)
    end

    self.traps = {}
    for _, trap_data in pairs(options.traps) do
        local trap = require('cls.trap.' .. trap_data.trap).new(unpack(trap_data.args))
        table.insert(self.traps, trap)
    end

    self.enemies = {}
    for _, enemy_data in pairs(options.enemies) do
        local enemy = require('cls.enemy.' .. enemy_data.enemy).new(unpack(enemy_data.args))
        table.insert(self.enemies, enemy)
    end

    self.treasure = {}
    for _, treasure_data in pairs(options.treasure) do
        local treasure = require('cls.level.' .. treasure_data.treasure).new(unpack(treasure_data.args))
        table.insert(self.treasure, treasure)
    end

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
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(trap.name, (x-1)*s, (y-1)*s)
    end
end

return level
