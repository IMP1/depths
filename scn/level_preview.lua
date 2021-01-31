local scene_manager = require 'lib.conductor'
local camera        = require 'lib.camera'
local level         = require 'cls.level.level'
local base_scene    = require 'scn._base'

local scene = {}
setmetatable(scene, base_scene)
scene.__index = scene

function scene.new(depth)
    local self = base_scene.new("Level Preview")
    setmetatable(self, scene)

    self.map = nil
    self.map_generator_status = "Pending"
    self.camera = camera.new()
    self.map_generator = level.generate({
        min_width  = 24,
        min_height = 24,
        max_width  = 32,
        max_height = 32,
        level_type = level.floor_types.CAVES,
        depth      = depth or 1,
        seed       = os.time(),
    })

    return self
end

function scene:keyPressed(key)
    if key == "r" and self.map then
        self.map = nil
        self.map_generator = nil
        self.map_generator_status = "Pending"
        self.map_generator = level.generate({
            min_width  = 24,
            min_height = 24,
            max_width  = 32,
            max_height = 32,
            seed = os.time(),
        })
    end
end

function scene:update(dt)
    local status = love.thread.getChannel("level-gen-status"):pop()
    if status then 
        self.map_generator_status = status
    end
    local map_result = love.thread.getChannel("level-gen"):pop()
    if map_result then
        self.map = level.new(map_result)
        self.map_generator:release()
        self.map_generator = nil
    end
end

local function room_under_mouse(level, x, y)
    for _, room in pairs(level.rooms) do
        if x >= room.x and 
           x <= room.x + room.width and 
           y >= room.y and 
           y <= room.y + room.height then
            return room
        end
    end
    return nil
end

function scene:draw()
    local SCALE = 16
    local mx, my = love.mouse.getPosition()
    local wx, wy = self.camera:toWorldPosition(mx - 100, my - 100)
    wx = math.floor(wx / SCALE) + 1
    wy = math.floor(wy / SCALE) + 1
    love.graphics.setColor(1, 1, 1)
    if self.map then
        love.graphics.push()
        love.graphics.translate(100, 100)
        self.camera:set()
        self:draw_map(SCALE)
        self.camera:unset()
        if love.keyboard.isDown("c") then
            for source_index, source in pairs(self.map.rooms) do
                local connections = 0
                local from_i = source.x
                local from_j = source.y
                for _, conn in pairs(self.map.connections) do
                    if conn.source == source_index or conn.target == source_index then
                        connections = connections + 1
                    end
                    if conn.source == source_index then
                        local target = self.map.rooms[conn.target]
                        from_i = conn.pos[1]
                        from_j = conn.pos[2]
                        local to_i = target.x
                        local to_j = target.y
                        if conn.dir[1] ~= 0 then
                            to_j = from_j
                            from_j = to_j
                            from_i = from_i
                            to_i = to_i
                        else
                            to_i = from_i
                            from_i = to_i
                            from_j = from_j
                            to_j = to_j
                        end
                        local from_x, from_y = self.camera:toScreenPosition(from_i - 1, from_j - 1)
                        local to_x, to_y = self.camera:toScreenPosition(to_i - 1, to_j - 1)
                        love.graphics.setColor(0, 0, 1)
                        love.graphics.setLineWidth(1)
                        love.graphics.rectangle("line", from_x * SCALE, from_y * SCALE, math.max(to_x - from_x, 1) * SCALE, math.max(to_y - from_y, 1) * SCALE)
                    end
                end
            end
        end
        love.graphics.pop()
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Map seed: " .. self.map.seed, 0, 0)
    end
    if not self.map then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self.map_generator_status, 0, 64, love.graphics.getWidth(), "center")
    end
    love.graphics.print("Mouse Position: " .. wx .. ", " .. wy, 0, 16)
end

function scene:draw_map(tile_size)
    local tile = level.tiles
    local s = tile_size or 1
    for j, row in pairs(self.map.tiles) do
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
    love.graphics.rectangle("line", (self.map.start_position.x - 1) * s, (self.map.start_position.y - 1) * s, s, s)
    love.graphics.rectangle("line", (self.map.end_position.x - 1) * s, (self.map.end_position.y - 1) * s, s, s)

    for _, trap in pairs(self.map.traps) do
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

return scene