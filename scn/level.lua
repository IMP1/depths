local scene_manager = require 'lib.conductor'
local camera        = require 'lib.camera'
local screenshake   = require 'lib.screenshake'
local level         = require 'cls.level.level'
local player        = require 'cls.player'
local base_scene    = require 'scn._base'

local scene = {}
setmetatable(scene, base_scene)
scene.__index = scene

function scene.new(party, depth)
    local self = base_scene.new("Level")
    setmetatable(self, scene)

    self.map = nil
    self.map_generator_status = "Pending"
    self.camera = camera.new()
    self.camera:scale(2)
    self.map_generator = level.generate({
        min_width  = 24,
        min_height = 24,
        max_width  = 32,
        max_height = 32,
        level_type = level.floor_types.CAVES,
        depth      = depth or 1,
        seed       = os.time(),
    })
    self.projectiles = {}
    self.popups = {}
    self.item_drops = {}
    self.visited = {}
    self.visible = {}
    self.exiting_map = false
    self.animations = {}
    self.traps = {}
    self.enemies = {}
    -- TODO: Push gate graphic animation to close behind the players to animations
    self.players = {}
    self.player_gamepads = {}
    for _, p in pairs(party) do
        local char = player.new(0, 0, 0, p.class_id, p.skin_id, p.gamepad)
        self.player_gamepads[p.gamepad] = char
        table.insert(self.players, char)
    end

    return self
end

local function reveal_map(self)
    for j, row in pairs(self.visible) do
        for i, tile in pairs(row) do
            self.visited[j][i] = true
            self.visible[j][i] = true
        end
    end
end

function scene:load()
    -- TODO: Change this to the be from the tileset
    -- TODO: This should therefor depend on the floor_type
    love.graphics.setBackgroundColor(0.25, 0.25, 0.3)
end

function scene:finalise_level()
    self.visited = {}
    self.visible = {}
    for j, row in pairs(self.map.tiles) do
        self.visited[j] = {}
        self.visible[j] = {}
        for i, t in pairs(row) do
            self.visited[j][i] = false
            self.visible[j][i] = false
        end
    end
    self.enemies = self.map.enemies
    self.traps = self.map.traps
    -- Setup Players
    local start_x = (self.map.start_position.x + 0.5) * level.TILE_SIZE
    local start_y = (self.map.start_position.y + 1) * level.TILE_SIZE
    local arc = math.pi / (#self.players + 1)
    print(start_x, start_y)
    for i, p in pairs(self.players) do
        local r = i * arc
        local x = start_x + math.cos(r) * level.TILE_SIZE
        local y = start_y + math.sin(r) * level.TILE_SIZE
        p.position.x = x
        p.position.y = y
        p.direction = r
    end
    self:update_game(0)
end

function scene:is_tile_opaque(i, j)
    local tile = self.map.tiles[j][i]
    return tile == level.tiles.NONE or 
           tile == level.tiles.WALL or
           tile == level.tiles.COLUMN or
           tile == level.tiles.FAKE_WALL
end

-- TODO: HANDLE PLAYER INPUT
-- TODO: HANDLE GAMEPAD REMOVAL

function scene:keyPressed(key)
    if key == "r" then
        reveal_map(self)
    end
end

function scene:update(dt)
    if self.map then
        self:update_game(dt)
        -- TODO: DEBUGGING, REMOVE:
        if love.keyboard.isDown("w") then
            self.camera:move(0, -dt * 128)
        end
        if love.keyboard.isDown("a") then
            self.camera:move(-dt * 128, 0)
        end
        if love.keyboard.isDown("s") then
            self.camera:move(0, dt * 128)
        end
        if love.keyboard.isDown("d") then
            self.camera:move(dt * 128, 0)
        end
    else
        self:update_level_generation()
    end
end

function scene:update_level_generation()
    local status = love.thread.getChannel("level-gen-status"):pop()
    if status then 
        self.map_generator_status = status
    end
    local map_result = love.thread.getChannel("level-gen"):pop()
    if map_result then
        self.map = level.new(map_result)
        self.map_generator:release()
        self.map_generator = nil
        self:finalise_level()
    end
end

function scene:update_game(dt)
    self:update_animations(dt)
    self:update_players(dt)
    self:update_camera(dt)
    -- self:update_enemies(dt)
    -- self:update_traps(dt)
    -- self:update_projectiles(dt)
    -- self:update_item_drops(dt)
    -- self:update_popups(dt)
    -- self:remove_dead()
    screenshake.update(dt)
end

function scene:update_animations(dt)
    for i = #self.animations, 1, -1 do
        local animation = self.animations[i]
        animation:update(dt)
        if animation.finished then
            table.remove(self.animations, i)
        end
    end
end

function scene:update_players(dt)
    for j, row in pairs(self.map.tiles) do
        for i, t in pairs(row) do
            self.visible[j][i] = false
        end
    end
    for _, p in pairs(self.players) do
        p:update(dt, self)
        p:update_visibility(self)
    end
end

function scene:update_camera(dt)
    if #self.players == 0 then return end
    local furthest_x, furthest_y = 0, 0
    local midpoint = self.players[1].position
    for i = 2, #self.players do
        midpoint = midpoint + self.players[i].position
    end
    midpoint = midpoint / #self.players
    self.camera:centreOn(midpoint.x, midpoint.y)
    -- TODO: get sensible zoom (with min of 1) that includes all players
end

function scene:draw()
    if not self.map then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self.map_generator_status, 0, 64, love.graphics.getWidth(), "center")
    else
        self:draw_game()
    end
end

function scene:draw_game()
    self.camera:set()
    screenshake.set()
    self:draw_map()
    screenshake.unset()
    self.camera:unset()
    self:draw_minimap()
    self:draw_hud()
end

function scene:draw_map()
    local tile_size = self.map.TILE_SIZE
    for j, row in pairs(self.map.tiles) do
        for i, t in pairs(row) do
            if self.visited[j][i] then
                local x, y = i * tile_size, j * tile_size
                local autotile = self.map.auto_tiles.floor[j][i]
                love.graphics.setColor(1, 1, 1)
                if (self.visited[j+1] or {})[i] then
                    love.graphics.draw(self.map.tilemap, self.map.tilemap_quads[autotile], x, y)
                end
                if not self.visible[j][i] then
                    love.graphics.setColor(0, 0, 0, 0.4)
                    love.graphics.rectangle("fill", x, y, tile_size, tile_size)
                end
            end
        end
    end
    love.graphics.setColor(1, 1, 1)
    for _, trap in pairs(self.traps) do
        trap:draw()
    end
    for _, enemy in pairs(self.enemies) do
        enemy:draw()
    end
    for _, player in pairs(self.players) do
        player:draw()
    end
    for _, projectile in pairs(self.projectiles) do
        projectile:draw()
    end
    for _, animation in pairs(self.animations) do
        animation:draw()
    end
    for j, row in pairs(self.map.tiles) do
        for i, t in pairs(row) do
            if self.visited[j][i] then
                local x, y = i * tile_size, j * tile_size
                local autotile = self.map.auto_tiles.ceiling[j][i]
                love.graphics.setColor(1, 1, 1)
                if autotile then
                    love.graphics.draw(self.map.tilemap, self.map.tilemap_quads[autotile], x, y - tile_size)
                end
            end
        end
    end
    for _, popup in pairs(self.popups) do
        popup:draw()
    end
end

function scene:draw_minimap()

end

function scene:draw_hud()
end

function scene:close()
    if self.map_generator then
        self.map_generator:release()
        self.map_generator = nil
    end
end

return scene