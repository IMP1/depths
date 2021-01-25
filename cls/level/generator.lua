local options = love.thread.getChannel("level-gen"):demand()

local mst = require('lib.minimum_spanning_tree')

local tile = require('cls.level.level').tile

local seed = options.seed or os.time()
math.randomseed(seed)

local MIN_WIDTH  = options.min_width  or 24
local MIN_HEIGHT = options.min_height or 24
local MAX_WIDTH  = options.max_width  or 32
local MAX_HEIGHT = options.max_height or 32


local gen = {}

function gen.update_status(message)
    love.thread.getChannel("level-gen-status"):push(message)
end

function gen.generate()
    local level = {}
    gen.update_status("Pre-Setup")

    level.seed = seed
    level.width = math.floor(math.random() * (MAX_WIDTH - MIN_WIDTH)) + MIN_WIDTH
    level.height = math.floor(math.random() * (MAX_HEIGHT - MIN_HEIGHT)) + MIN_HEIGHT
    level.tiles = {}
    for j = 1, level.height do
        level.tiles[j] = {}
        for i = 1, level.width do
            level.tiles[j][i] = tile.NONE
        end
    end

    level.traps = {}
    level.fake_walls = {}
    level.enemies = {}
    level.treasure = {}
    level.rooms = {}
    level.hidden_rooms = {}
    level.auto_tiles = {}
    level.start_position = {}
    level.end_position = {}
    level.boss_position = {}

    gen.update_status("Generating...")

    gen.create_layout(level)
    gen.create_auto_tiles(level)
    gen.add_traps(level)
    gen.add_enemies(level)
    gen.add_treasure(level)

    gen.update_status("Finished.")
    return level
end

function gen.get_tile(level, x, y)
    if level.tiles[y] and level.tiles[y][x] then
        return level.tiles[y][x]
    end
    return tile.NONE
end

function gen.is_wall(level, x, y)
    local t = gen.get_tile(level, x, y)
    return t == tile.WALL_TOP or t == tile.WALL_SIDE or t == tile.WALL_DEBUG
end

function gen.is_exit(level, x, y)
    if level.start_position.x == x and level.start_position.y == y then return true end
    if level.end_position.x == x and level.end_position.y == y then return true end
    return false
end

function gen.is_floor(level, x, y)
    local t = gen.get_tile(level, x, y)
    return t == tile.FLOOR or t == tile.FLOOR_START or t == tile.FLOOR_END or t == tile.FLOOR_BOSS or t == tile.FLOOR_DEBUG
end

function gen.is_in_room(x, y, room)
   return x >= room.x and 
          x <= room.x + room.width and 
          y >= room.y and 
          y <= room.y + room.height
end

function gen.room_overlap(room1, room2)
    if (room1.x > room2.x + room2.width or room2.x > room1.x + room1.width) then
        return false
    end
    if (room1.y > room2.y + room2.height or room2.y > room1.y + room1.height) then
        return false
    end
    return true
end

function gen.set_tile(level, x, y, tile_type, ...)
    local overwrite = {...}
    if #overwrite == 0 then
        overwrite = {}
        for k, v in pairs(tile) do
            overwrite[v] = true
        end
    elseif #overwrite == 1 then
        if type(overwrite[1]) == "boolean" then
            local overwrite_all = overwrite[1]
            overwrite = {}
            for k, v in pairs(tile) do
                overwrite[v] = true
            end            
        else
            overwrite = {}
            for k, v in pairs({...}) do
                overwrite[v] = true
            end
        end
    else
        overwrite = {}
        for k, v in pairs({...}) do
            overwrite[v] = true
        end
    end 
    if x == level.start_position.x and y == level.start_position.y then return end
    if x == level.end_position.x and y == level.end_position.y then return end
    if y < 1 or y > level.height then return end
    if x < 1 or x > level.width then return end
    local current_tile = level.tiles[y][x]
    if overwrite[current_tile] or current_tile == tile.NONE then
        level.tiles[y][x] = tile_type
    end
end

local function is_space_at(level, x, y, width, height)
    if x < 1 or x + width > level.width then return false end
    if y < 1 or y + height > level.height then return false end
    for _, room in pairs(level.rooms) do
        if gen.room_overlap({x=x, y=y, width=width, height=height}, room) then 
            return false 
        end
    end
    return true
end

function gen.create_layout(level)
    gen.add_rooms(level)
    gen.join_rooms(level)
    gen.fill_up(level)
    -- gen.hide_rooms(level)
    -- gen.add_columns(level)
    -- gen.ensure_wall_thickness(level)
end

function gen.add_rooms(level)
    gen.update_status("Adding rooms...")
    -- Add necessary rooms
    repeat
        local start_room = gen.add_random_room(level, 4, 3, tile.FLOOR_START)
        local end_room = gen.add_random_room(level, 4, 3, tile.FLOOR_END)
        local boss_room = gen.add_random_room(level, 6, 5, tile.FLOOR_BOSS)
        if start_room and end_room and boss_room then
            local start_x = start_room.x + math.floor(math.random() * start_room.width)
            local end_x = end_room.x + math.floor(math.random() * end_room.width)
            local boss_x = boss_room.x + math.floor(math.random() * boss_room.width)
            local boss_y = boss_room.y + math.floor(math.random() * boss_room.height)
            level.start_position = {x = start_x, y = start_room.y - 1}
            level.end_position = {x = end_x, y = end_room.y - 1}
            level.boss_position = {x = boss_x, y = boss_y}
        end
    until start_room and end_room and boss_room
    -- Add optional rooms
    local no_room_prob = 0.1
    local large_room_count = 3 + math.floor(math.random() * 4)
    for i = 1, large_room_count do
        local w = 4 + math.floor(math.random() * 4)
        local h = 3 + math.floor(math.random() * 4)
        local tile_type = tile.FLOOR
        if math.random() < no_room_prob then tile_type = tile.WALL_TOP end
        gen.add_random_room(level, w, h, tile_type)
    end
    local medium_room_count = 5 + math.floor(math.random() * 4)
    for i = 1, medium_room_count do
        local w = 3 + math.floor(math.random() * 3)
        local h = 2 + math.floor(math.random() * 5)
        local tile_type = tile.FLOOR
        if math.random() < no_room_prob then tile_type = tile.WALL_TOP end
        gen.add_random_room(level, w, h, tile_type)
    end
    local small_room_count = 7 + math.floor(math.random() * 4)
    for i = 1, small_room_count do
        local w = 2 + math.floor(math.random() * 2)
        local h = 2 + math.floor(math.random() * 2)
        local tile_type = tile.FLOOR
        if math.random() < no_room_prob then tile_type = tile.WALL_TOP end
        gen.add_random_room(level, w, h, tile_type)
    end
    -- Add long 'corridor' rooms
    for i = 1, 3 do
        local w = 8 + math.floor(math.random() * 2)
        local h = 1
        gen.add_random_room(level, w, h, tile.FLOOR)
    end
    for i = 1, 3 do
        local w = 1
        local h = 8 + math.floor(math.random() * 2)
        gen.add_random_room(level, w, h, tile.FLOOR)
    end
    for i = 1, 3 do
        local w = 6 + math.floor(math.random() * 3)
        local h = 1
        gen.add_random_room(level, w, h, tile.FLOOR)
    end
    for i = 1, 3 do
        local w = 1
        local h = 6 + math.floor(math.random() * 3)
        gen.add_random_room(level, w, h, tile.FLOOR)
    end
    for i = 1, 4 do
        local w = 4 + math.floor(math.random() * 3)
        local h = 1
        gen.add_random_room(level, w, h, tile.FLOOR)
    end
    for i = 1, 4 do
        local w = 1
        local h = 4 + math.floor(math.random() * 3)
        gen.add_random_room(level, w, h, tile.FLOOR)
    end
end

function gen.add_random_room(level, width, height, tile_type)
    local random_pos = math.floor(math.random() * level.width * level.height)
    for n = random_pos, level.width * level.height do
        local x = n % level.width
        local y = math.floor(n / level.width)
        if is_space_at(level, x-1, y-1, width+2, height+2) then
            return gen.add_room(level, x, y, width, height, tile_type)
        end
    end
    for n = random_pos, 1, -1 do
        local x = n % level.width
        local y = math.floor(n / level.width)
        if is_space_at(level, x-1, y-1, width+2, height+2) then
            return gen.add_room(level, x, y, width, height, tile_type)
        end
    end
    return nil
end

function gen.add_room(level, x, y, width, height, floor_type, wall_type)
    for j = y - 1, y + height + 1 do
        for i = x - 1, x + width + 1 do
            gen.set_tile(level, i, j, wall_type or tile.WALL_TOP)
        end
    end
    for j = y, y + height do
        for i = x, x + width do
            gen.set_tile(level, i, j, floor_type or tile.FLOOR)
        end
    end
    local room = {x = x, y = y, width = width, height = height}
    table.insert(level.rooms, room)
    return room
end

function gen.join_rooms(level)
    local passage_edges = gen.random_spanning_tree(level)
    for _, edge in pairs(passage_edges) do
        local source = level.rooms[edge.source]
        local target = level.rooms[edge.target]
        print("(" .. source.x .. "," .. source.y .. ")", "->", "(" .. target.x .. "," .. target.y .. ")")
    end
    -- TODO: Create passages following edges of MST(s)
    -- gen.create_passages(level)
end

function gen.random_spanning_tree(level)
    local graph = gen.create_room_graph(level)
    local passage_edges = {}
    for i = 1, math.floor(math.random() * 2) + 1 do
        for _, edge in pairs(graph[2]) do
            edge.length = math.random()
        end
        local mst, unconnected_rooms = mst.minimum_spanning_tree(graph)
        for _, edge in pairs(mst) do
            table.insert(passage_edges, edge)
        end
    end
    return passage_edges
end

function gen.create_room_graph(level)
    local nodes = {}
    local edges = {}

    for room_index, room in pairs(level.rooms) do
        table.insert(nodes, room_index)
        local nearest_rooms_east = {}
        do
            local i = room.x + room.width + 1
            for j = room.y, room.y + room.height do
                local nearest = gen.find_nearest_room_index(level, i, j, 1, 0)
                if nearest then
                    if not nearest_rooms_east[nearest] then
                        nearest_rooms_east[nearest] = {}
                    end
                    table.insert(nearest_rooms_east[nearest], j)
                end
            end
        end
        local nearest_rooms_south = {}
        do
            local j = room.y + room.height + 1
            for i = room.x, room.x + room.width do
                local nearest = gen.find_nearest_room_index(level, i, j, 0, 1)
                if nearest then
                    if not nearest_rooms_south[nearest] then
                        nearest_rooms_south[nearest] = {}
                    end
                    table.insert(nearest_rooms_south[nearest], i)
                end
            end
        end
        -- print("Room connections:", room.x, room.y)
        -- print("To east:")
        for k, v in pairs(nearest_rooms_east) do
            local adj_room = level.rooms[k]
            local length = adj_room.x - (room.x + room.width)
            local x = room.x + room.width + 1
            local y = v[math.floor(math.random() * #v) + 1]
            table.insert(edges, {source = room_index, target = k, pos = {x, y}, dir = {1, 0}, length = length})
            -- print(adj_room.x, adj_room.y)
            -- print(unpack(v))
        end
        -- print("To south:")
        for k, v in pairs(nearest_rooms_south) do
            local adj_room = level.rooms[k]
            local length = adj_room.y - (room.y + room.height)
            local x = v[math.floor(math.random() * #v) + 1]
            local y = room.y + room.height + 1
            table.insert(edges, {source = room_index, target = k, pos = {offset, 0}, dir = {0, 1}, length = length})
        --     print(adj_room.x, adj_room.y)
        --     print(unpack(v))
        end
        -- io.flush()
        -- break
    end
    -- TODO: Find edges {source, target, length}
    return {nodes, edges}
end

function gen.find_nearest_room_index(level, x, y, dx, dy)
    while gen.is_wall(level, x, y) and not gen.is_exit(level, x, y) and not gen.is_exit(level, x, y - 1) do
        x = x + dx
        y = y + dy
    end
    if gen.is_floor(level, x, y) then
        for index, room in ipairs(level.rooms) do
            if gen.is_in_room(x, y, room) then
                return index
            end
        end
    end
    return nil
end

function gen.fill_up(level)
    gen.update_status("Filling empty space...")
    for j = 1, level.height do
        for i = 1, level.width do
            if gen.get_tile(level, i, j) == tile.NONE then
                gen.set_tile(level, i, j, tile.WALL_TOP)
            end
        end
    end
end

function gen.hide_rooms(level)
    gen.update_status("Hiding rooms...")
    local probability = 0.1
    for _, r in pairs(level.rooms) do
        if math.random() < probability then
            table.insert(level.hidden_rooms, r)
            for j = r.y - 1, r.y + r.height + 1 do
                if gen.is_floor(level, r.x-1, j) and not gen.is_exit(level, r.x-1, j-1) then
                    gen.set_tile(level, r.x-1, j, tile.FAKE_WALL)
                end
                if gen.is_floor(level, r.x+r.width, j) and not gen.is_exit(level, r.x+r.width, j-1) then
                    gen.set_tile(level, r.x+r.width, j, tile.FAKE_WALL)
                end
            end
            for i = r.x - 1, r.x + r.width + 1 do
                if gen.is_floor(level, i, r.y-1) and not gen.is_exit(level, i, r.y-1) and not gen.is_exit(level, i, r.y-2) then
                    gen.set_tile(level, i, r.y-1)
                    if gen.is_wall(level, i-1, r.y) or gen.is_wall(level, i+1, r.y) then
                        gen.set_tile(level, i, r.y)
                    else
                        gen.set_tile(level, i, r.y-2)
                    end
                end
                if gen.is_floor(level, i, r.y+r.height) and not gen.is_exit(level, i, r.y+r.height) and not gen.is_exit(level, i, r.y+r.height-1) then
                    gen.set_tile(level, i, r.y+r.height)
                    if gen.is_wall(level, i-1, r.y+r.height) or gen.is_wall(level, i+1, r.y+r.height) then
                        gen.set_tile(level, i, r.y+r.height)
                    else
                        gen.set_tile(level, i, r.y+r.height-1)
                    end
                end
            end
        end
    end
end

function gen.add_columns(level)
    gen.update_status("Adding columns...")
end

function gen.ensure_wall_thickness(level)
end

function gen.create_auto_tiles(level)
end

function gen.add_traps(level)
end

function gen.add_enemies(level)
end

function gen.add_treasure(level)
end




local level = gen.generate()

love.thread.getChannel("level-gen"):supply(level)
