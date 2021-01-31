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
    self.fake_walls = {}
    for _, fake_wall in pairs(options.fake_walls) do
        local class = fake_wall.class
        local args = fake_wall.args
        table.insert(self.fake_walls, require(class).new(unpack(args)))
    end
    self.traps = {}
    for _, trap in pairs(options.traps) do
        local class = trap.class
        local args = trap.args
        table.insert(self.traps, require(class).new(unpack(args)))
    end
    self.enemies = {}
    for _, enemy in pairs(options.enemies) do
        local class = enemy.class
        local args = enemy.args
        table.insert(self.enemies, require(class).new(unpack(args)))
    end
    self.treasure = {}
    for _, treasure in pairs(options.treasure) do
        local class = treasure.class
        local args = treasure.args
        table.insert(self.treasure, require(class).new(unpack(args)))
    end

    return self
end

function level:refresh_auto_tiles()
end

function level:draw(tile_size)
    
end

return level
