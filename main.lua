local level = require 'cls.level.level'
local Camera = require 'lib.camera'

local map = nil
local map_generator = nil
map_generator_status = "Pending"
local camera = Camera.new()

function love.load()
    map_generator = level.generate({
        min_width  = 24,
        min_height = 24,
        max_width  = 32,
        max_height = 32,
        seed = os.time(),
    })
    camera:scale(16)
end

function love.keypressed(key)
    if key == "r" and map then
        map = nil
        map_generator = nil
        map_generator_status = "Pending"
        map_generator = level.generate({
            min_width  = 24,
            min_height = 24,
            max_width  = 32,
            max_height = 32,
            seed = os.time(),
        })
    end
end

function love.threaderror(thread, error_message)
    error(error_message)
end

function love.update(dt)
    local status = love.thread.getChannel("level-gen-status"):pop()
    if status then 
        map_generator_status = status
    end
    local map_result = love.thread.getChannel("level-gen"):pop()
    if map_result then
        map = level.new(map_result)
        map_generator:release()
        map_generator = nil
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

function love.draw()
    local mx, my = love.mouse.getPosition()
    local wx, wy = camera:toWorldPosition(mx - 100, my - 100)
    wx = math.floor(wx) + 1
    wy = math.floor(wy) + 1
    love.graphics.setColor(1, 1, 1)
    if map then
        love.graphics.push()
        love.graphics.translate(100, 100)
        camera:set()
        map:draw()
        -- TODO: Get room under mouse (if any) and draw connections over the map
        camera:unset()
        if love.keyboard.isDown("lshift") then
            love.graphics.setColor(0, 0, 0, 0.3)
            love.graphics.setLineWidth(camera.scaleX)
            for source_index, source in pairs(map.rooms) do
                local connections = 0
                local from_i = source.x
                local from_j = source.y
                for _, conn in pairs(map.connections) do
                    if conn.source == source_index or conn.target == source_index then
                        connections = connections + 1
                    end
                    if conn.source == source_index then
                        local target = map.rooms[conn.target]
                        from_i = conn.pos[1]
                        from_j = conn.pos[2]
                        local to_i = target.x
                        local to_j = target.y
                        if conn.dir[1] ~= 0 then
                            to_j = from_j - 0.5
                            from_j = to_j
                            from_i = from_i - 1
                            to_i = to_i - 1
                        else
                            to_i = from_i - 0.5
                            from_i = to_i
                            from_j = from_j - 1
                            to_j = to_j - 1
                        end
                        local from_x, from_y = camera:toScreenPosition(from_i, from_j)
                        local to_x, to_y = camera:toScreenPosition(to_i, to_j)
                        love.graphics.line(from_x, from_y, to_x, to_y)
                    end
                end
                if connections == 0 then
                    camera:set()
                    love.graphics.rectangle("fill", source.x - 1, source.y - 1, source.width + 1, source.height + 1)
                    camera:unset()
                end
            end
        end
        love.graphics.pop()
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Map seed: " .. map.seed, 0, 0)
    end
    if not map then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(map_generator_status, 0, 64, love.graphics.getWidth(), "center")
    end
    love.graphics.print("Mouse Position: " .. wx .. ", " .. wy, 0, 16)
end