local options = love.thread.getChannel("level-gen"):demand()

local mst = require('lib.minimum_spanning_tree')

local TILE = require('cls.level.level').tiles
local FLOOR_TYPE = require('cls.level.level').floor_types

local seed = options.seed or os.time()
math.randomseed(seed)

local MIN_WIDTH  = options.min_width  or 24
local MIN_HEIGHT = options.min_height or 24
local MAX_WIDTH  = options.max_width  or 32
local MAX_HEIGHT = options.max_height or 32


local level_type  = options.level_type or FLOOR_TYPE.CAVES
local level_depth = options.depth      or 1

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
            level.tiles[j][i] = TILE.NONE
        end
    end

    level.depth = level_depth
    level.floor_type = level_type
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
    gen.create_content(level)
    gen.finalise(level)

    gen.update_status("Finished.")
    return level
end

function gen.get_tile(level, x, y)
    if level.tiles[y] and level.tiles[y][x] then
        return level.tiles[y][x]
    end
    return TILE.NONE
end

function gen.is_wall(level, x, y, include_fakes)
    local t = gen.get_tile(level, x, y)
    if include_fakes and t == TILE.FAKE_WALL then
        return true
    end
    return t == TILE.WALL or t == TILE.COLUMN
end

function gen.is_exit(level, x, y)
    if level.start_position.x == x and level.start_position.y == y then return true end
    if level.end_position.x == x and level.end_position.y == y then return true end
    return false
end

function gen.is_floor(level, x, y)
    local t = gen.get_tile(level, x, y)
    return t == TILE.FLOOR or 
           t == TILE.FLOOR_START or 
           t == TILE.FLOOR_END or 
           t == TILE.FLOOR_BOSS or 
           t == TILE.FLOOR_HALL
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
        for k, v in pairs(TILE) do
            overwrite[v] = true
        end
    elseif #overwrite == 1 then
        if type(overwrite[1]) == "boolean" then
            local overwrite_all = overwrite[1]
            overwrite = {}
            for k, v in pairs(TILE) do
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
    if overwrite[current_tile] or current_tile == TILE.NONE then
        level.tiles[y][x] = tile_type
    end
end

function gen.is_space_at(level, x, y, width, height)
    if x < 1 or x + width > level.width then return false end
    if y < 1 or y + height > level.height then return false end
    for _, room in pairs(level.rooms) do
        if gen.room_overlap({x=x, y=y, width=width, height=height}, room) then 
            return false 
        end
    end
    return true
end

function gen.is_trap_at(level, x, y)
    for _, t in pairs(level.traps) do
        if t.temp_obj:is_at_tile(x, y) then 
            return true 
        end
    end
    return false
end

function gen.create_layout(level)
    gen.create_rooms(level)
    gen.join_rooms(level)
    gen.fill_empty_space(level)
    gen.hide_rooms(level)
    gen.create_columns(level)
    -- gen.ensure_wall_thickness(level)
end

function gen.create_rooms(level)
    gen.update_status("Adding rooms...")
    -- Add necessary rooms
    repeat
        local start_room = gen.add_random_room(level, 4, 3, TILE.FLOOR_START)
        local end_room = gen.add_random_room(level, 4, 3, TILE.FLOOR_END)
        local boss_room = gen.add_random_room(level, 6, 5, TILE.FLOOR_BOSS)
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
    local large_room_count = 2 + math.random(4)
    for i = 1, large_room_count do
        local w = 3 + math.random(4)
        local h = 2 + math.random(4)
        local tile_type = TILE.FLOOR
        if math.random() < no_room_prob then tile_type = TILE.WALL end
        gen.add_random_room(level, w, h, tile_type)
    end
    local medium_room_count = 4 + math.random(4)
    for i = 1, medium_room_count do
        local w = 2 + math.random(3)
        local h = 1 + math.random(5)
        local tile_type = TILE.FLOOR
        if math.random() < no_room_prob then tile_type = TILE.WALL end
        gen.add_random_room(level, w, h, tile_type)
    end
    local small_room_count = 7 + math.floor(math.random() * 4)
    for i = 1, small_room_count do
        local w = 1 + math.random(2)
        local h = 1 + math.random(2)
        local tile_type = TILE.FLOOR
        if math.random() < no_room_prob then tile_type = TILE.WALL end
        gen.add_random_room(level, w, h, tile_type)
    end
    -- Add long 'corridor' rooms
    for i = 1, 3 do
        local w = 7 + math.random(2)
        local h = 1
        gen.add_random_room(level, w, h, TILE.FLOOR)
    end
    for i = 1, 3 do
        local w = 1
        local h = 7 + math.random(2)
        gen.add_random_room(level, w, h, TILE.FLOOR)
    end
    for i = 1, 3 do
        local w = 5 + math.random(3)
        local h = 1
        gen.add_random_room(level, w, h, TILE.FLOOR)
    end
    for i = 1, 3 do
        local w = 1
        local h = 5 + math.random(3)
        gen.add_random_room(level, w, h, TILE.FLOOR)
    end
    for i = 1, 4 do
        local w = 3 + math.random(3)
        local h = 1
        gen.add_random_room(level, w, h, TILE.FLOOR)
    end
    for i = 1, 4 do
        local w = 1
        local h = 3 + math.random(3)
        gen.add_random_room(level, w, h, TILE.FLOOR)
    end
end

function gen.add_random_room(level, width, height, tile_type)
    local random_pos = math.random(level.width * level.height)
    for n = random_pos, level.width * level.height do
        local x = n % level.width
        local y = math.floor(n / level.width)
        if gen.is_space_at(level, x-1, y-1, width+2, height+2) then
            return gen.add_room(level, x, y, width, height, tile_type)
        end
    end
    for n = random_pos, 1, -1 do
        local x = n % level.width
        local y = math.floor(n / level.width)
        if gen.is_space_at(level, x-1, y-1, width+2, height+2) then
            return gen.add_room(level, x, y, width, height, tile_type)
        end
    end
    return nil
end

function gen.add_room(level, x, y, width, height, floor_type, wall_type)
    for j = y - 1, y + height + 1 do
        for i = x - 1, x + width + 1 do
            gen.set_tile(level, i, j, wall_type or TILE.WALL)
        end
    end
    for j = y, y + height do
        for i = x, x + width do
            gen.set_tile(level, i, j, floor_type or TILE.FLOOR)
        end
    end
    local room = {x = x, y = y, width = width, height = height}
    table.insert(level.rooms, room)
    return room
end

function gen.join_rooms(level)
    gen.remove_non_rooms(level)
    gen.add_passages(level)
end

function gen.remove_non_rooms(level)
    for i = #level.rooms, 1, -1 do
        local room = level.rooms[i]
        local x, y = room.x, room.y
        if gen.is_wall(level, x, y) then
            table.remove(level.rooms, i)
        end
    end
end

function gen.add_passages(level)
    local passage_edges = gen.random_spanning_tree(level)
    for _, connection in pairs(passage_edges) do
        local source = level.rooms[connection.source]
        local target = level.rooms[connection.target]
        local from_i, from_j = unpack(connection.pos)
        local to_i = from_i + connection.length * connection.dir[1]
        local to_j = from_j + connection.length * connection.dir[2]
        local width = to_i - from_i
        local height = to_j - from_j
        gen.add_corridor(level, from_i, from_j, width, height)
    end
    -- TODO: Remove this once generation is finished.
    --       It's used for visualising the intermediate outputs
    level.connections = passage_edges
end

function gen.random_spanning_tree(level)
    local graph = gen.create_room_graph(level)
    local passage_edges = {}
    for i = 1, math.random(3) do
        for _, edge in pairs(graph[2]) do
            edge.weight = math.random()
        end
        local mst, unconnected_rooms = mst.minimum_spanning_tree(graph)
        if #unconnected_rooms > 0 then
            print("Isolated Rooms!")
            for _, room_id in pairs(unconnected_rooms) do
                local room = level.rooms[room_id]
                print(room.x, room.y)
            end
            print()
        end
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
            local length = adj_room.x - (room.x + room.width + 1) - 1
            local x = room.x + room.width + 1
            local y = v[math.random(#v)]
            table.insert(edges, {source = room_index, target = k, pos = {x, y}, dir = {1, 0}, length = length, weight = length})
            -- print(adj_room.x, adj_room.y)
            -- print(unpack(v))
        end
        -- print("To south:")
        for k, v in pairs(nearest_rooms_south) do
            local adj_room = level.rooms[k]
            local length = adj_room.y - (room.y + room.height + 1) - 1
            local x = v[math.random(#v)]
            local y = room.y + room.height + 1
            table.insert(edges, {source = room_index, target = k, pos = {x, y}, dir = {0, 1}, length = length, weight = length})
        --     print(adj_room.x, adj_room.y)
        --     print(unpack(v))
        end
        -- io.flush()
        -- break
    end
    return {nodes, edges}
end

function gen.find_nearest_room_index(level, x, y, dx, dy)
    while gen.is_wall(level, x, y) and not gen.is_exit(level, x, y) and not gen.is_exit(level, x, y - 1) do
        x = x + dx
        y = y + dy
    end
    if gen.is_floor(level, x, y) and not gen.is_exit(level, x, y - 1) then
        for index, room in ipairs(level.rooms) do
            if gen.is_in_room(x, y, room) then
                return index
            end
        end
    end
    return nil
end

function gen.add_corridor(level, x, y, width, height, add_room)
    for j = y, y + height do
        for i = x, x + width do
            gen.set_tile(level, i, j, TILE.FLOOR_HALL)
        end
    end
    local room = {x = x, y = y, width = width, height = height}
    table.insert(level.rooms, room)
end

function gen.fill_empty_space(level)
    gen.update_status("Filling empty space...")
    for j = 1, level.height do
        for i = 1, level.width do
            if gen.get_tile(level, i, j) == TILE.NONE then
                gen.set_tile(level, i, j, TILE.WALL)
            end
        end
    end
end

function gen.hide_rooms(level)
    gen.update_status("Hiding rooms...")
    local probability = 0.1
    for _, r in pairs(level.rooms) do
        local size = r.width * r.height
        if size > 2 and math.random() < probability then
            table.insert(level.hidden_rooms, r)
            for j = r.y - 1, r.y + r.height + 1 do
                if gen.is_floor(level, r.x-1, j) and not gen.is_exit(level, r.x-1, j-1) then
                    gen.set_tile(level, r.x-1, j, TILE.FAKE_WALL)
                end
                if gen.is_floor(level, r.x+r.width+1, j) and not gen.is_exit(level, r.x+r.width+1, j-1) then
                    gen.set_tile(level, r.x+r.width+1, j, TILE.FAKE_WALL)
                end
            end
            for i = r.x - 1, r.x + r.width + 1 do
                if gen.is_floor(level, i, r.y-1) and not gen.is_exit(level, i, r.y-2) then
                    gen.set_tile(level, i, r.y-1, TILE.FAKE_WALL)
                end
                if gen.is_floor(level, i, r.y+r.height+1) and not gen.is_exit(level, i, r.y+r.height) then
                    gen.set_tile(level, i, r.y+r.height+1, TILE.FAKE_WALL)
                end
            end
        end
    end
end

function gen.create_columns(level)
    gen.update_status("Adding columns...")
    local probability = 0.05
    for j, row in pairs(level.tiles) do
        for i, t in pairs(row) do
            local enough_space = gen.is_floor(level, i-1, j-1) and
                                 gen.is_floor(level, i,   j-1) and
                                 gen.is_floor(level, i+1, j-1) and
                                 gen.is_floor(level, i-1, j) and
                                 gen.is_floor(level, i,   j) and
                                 gen.is_floor(level, i+1, j) and
                                 gen.is_floor(level, i-1, j+1) and
                                 gen.is_floor(level, i,   j+1) and
                                 gen.is_floor(level, i+1, j+1)
            local occupied = gen.is_trap_at(level, i, j)
            local obscuring = gen.is_trap_at(level, i, j-1) or
                              gen.is_exit(level, i, j-2)
            if enough_space and not occupied and not obscuring and math.random() < probability then
                gen.set_tile(level, i, j, TILE.COLUMN)
            end
        end
    end
end

function gen.create_auto_tiles(level)
    level.auto_tiles.floor = {}
    level.auto_tiles.ceiling = {}
    for j, row in pairs(level.tiles) do
        level.auto_tiles.floor[j] = {}
        level.auto_tiles.ceiling[j] = {}
        for i, t in pairs(row) do
            level.auto_tiles.floor[j][i] = gen.floor_autotile_value(level, i, j)
            level.auto_tiles.ceiling[j][i] = gen.ceiling_autotile_value(level, i, j)
        end
    end
end

function gen.floor_autotile_value(level, i, j)
    -- TODO: Get tileset from level.floor_type
    -- TODO: A tileset might have different/more floor tiles
    if level.start_position.x == i and level.start_position.y == j then
        return 1
    end
    if level.end_position.x == i and level.end_position.y == j then
        return 2
    end
    if level.floor_type == FLOOR_TYPE.CAVES then
        if gen.is_floor(level, i, j) then
            if math.random() < 0.01 then
                return 5
            elseif math.random() < 0.02 then
                return 4
            else
                return 3
            end
        end
        if gen.is_wall(level, i, j, true) then
            if math.random() < 0.02 then
                return 10
            elseif math.random() < 0.02 then
                return 9
            else
                return 8
            end
        end
    -- TODO: Handle other map types
    end
    return 0
end

function gen.ceiling_autotile_value(level, i, j)
    if level.floor_type == FLOOR_TYPE.CAVES then
        if gen.is_wall(level, i, j, true) then
            local binary_flag_sum = 0
            if not gen.is_wall(level, i + 1, j, true) and gen.get_tile(level, i + 1, j) ~= TILE.NONE then
                binary_flag_sum = binary_flag_sum + 1
            end
            if not gen.is_wall(level, i, j + 1, true) and gen.get_tile(level, i, j + 1) ~= TILE.NONE then
                binary_flag_sum = binary_flag_sum + 2
            end
            if not gen.is_wall(level, i - 1, j, true) and gen.get_tile(level, i - 1, j) ~= TILE.NONE then
                binary_flag_sum = binary_flag_sum + 4
            end
            if not gen.is_wall(level, i, j - 1, true) and gen.get_tile(level, i, j - 1) ~= TILE.NONE then
                binary_flag_sum = binary_flag_sum + 8
            end
            return binary_flag_sum + 16
        end
    -- TODO: Handle other map types
    end
    return nil
end

function gen.create_content(level)
    gen.create_traps(level)
    gen.create_enemies(level)
    gen.create_treasure(level)
end

function gen.create_traps(level)
    gen.update_status("Adding traps...")
    gen.create_boulder_traps(level)
    gen.create_spike_traps(level)
    -- gen.create_swinging_traps(level)
    gen.create_arrow_traps(level)
end

function gen.create_boulder_traps(level)
    local corridor_probability = 0.2
    local open_space_probability = 0.1
    for _, r in pairs(level.rooms) do
        local long = (r.width > 3 and r.height == 1) or
                     (r.width == 0 and r.height > 3)
        if (long and math.random() < corridor_probability) or (math.random() < open_space_probability) then
            gen.create_boulder_trap(level, r)
        end
    end
end

function gen.create_boulder_trap(level, room)
    local trap_x = room.x + math.random(room.width)
    local trap_y = room.y + math.random(room.height)
    local boulder_x = trap_x
    local boulder_y = trap_y
    local minimum_distance = 3
    local direction = math.random(4)
    for dir = direction, direction + 3 do
        local dx, dy = 0, 0
        if dir % 4 == 0 then
            dx, dy = 1, 0
        elseif dir % 4 == 1 then
            dx, dy = 0, 1
        elseif dir % 4 == 2 then
            dx, dy = -1, 0
        elseif dir % 4 == 3 then
            dx, dy = 0, -1
        end
        boulder_x = boulder_x
        boulder_y = boulder_y
        while gen.is_floor(level, boulder_x + dx, boulder_y + dy) do
            boulder_x = boulder_x + dx
            boulder_y = boulder_y + dy
        end
        if math.abs(boulder_x - trap_x) >= minimum_distance or math.abs(boulder_y - trap_y) >= minimum_distance then
            break
        else
            boulder_x, boulder_y = trap_x, trap_y
        end
    end

    local no_boulder_position = boulder_x == trap_x and boulder_y == trap_y
    if no_boulder_position then
        return
    end

    local min_distance_from_exit = 3
    local too_near_exit = math.abs(trap_x - level.start_position.x)    + math.abs(trap_y - level.start_position.y)    < min_distance_from_exit or 
                          math.abs(trap_x - level.end_position.x)      + math.abs(trap_y - level.end_position.y)      < min_distance_from_exit or 
                          math.abs(boulder_x - level.start_position.x) + math.abs(boulder_y - level.start_position.y) < min_distance_from_exit or 
                          math.abs(boulder_x - level.end_position.x)   + math.abs(boulder_y - level.end_position.y)   < min_distance_from_exit
    if too_near_exit then 
        return 
    end

    local occupied = gen.is_trap_at(level, trap_x, trap_y) or gen.is_trap_at(level, boulder_x, boulder_y)
    if occupied then
        return
    end

    if gen.is_floor(level, trap_x, trap_y) and gen.is_floor(level, boulder_x, boulder_y) then
        local trap = {
            class = 'cls.trap.boulder',
            args = {trap_x, trap_y, boulder_x, boulder_y},
            temp_obj = require('cls.trap.boulder').new(trap_x, trap_y, boulder_x, boulder_y),
        }
        table.insert(level.traps, trap)
    end
end

function gen.create_spike_traps(level)
    local probability = 0.01
    local min_distance_from_exit = 3
    for j, row in pairs(level.tiles) do
        for i, t in pairs(row) do
            local occupied = gen.is_trap_at(level, i, j)
            local too_near_exit = math.abs(i - level.start_position.x) + math.abs(j - level.start_position.y) < min_distance_from_exit or 
                                  math.abs(i - level.end_position.x) + math.abs(j - level.end_position.y) < min_distance_from_exit
            if gen.is_floor(level, i, j) and not occupied and not too_near_exit and math.random() < probability then
                local trap = {
                    class = 'cls.trap.spike',
                    args = {i, j},
                    temp_obj = require('cls.trap.spike').new(i, j),
                }
                table.insert(level.traps, trap)
            end
        end
    end
end

function gen.create_swinging_traps(level)
    local probability = 0.2
    for j, row in pairs(level.tiles) do
        for i, t in pairs(row) do
            local vertical_passage = gen.is_floor(level, i, j) and 
                                     gen.is_floor(level, i, j-1) and 
                                     gen.is_floor(level, i, j+1) and 
                                     not gen.is_trap_at(level, i, j) and
                                     not gen.is_trap_at(level, i, j-1) and
                                     not gen.is_trap_at(level, i, j+1) and
                                     gen.is_wall(level, i-1, j) and
                                     gen.is_wall(level, i+1, j) and
                                     gen.is_wall(level, i-1, j-1) and
                                     gen.is_wall(level, i+1, j-1) and
                                     gen.is_wall(level, i-1, j+1) and
                                     gen.is_wall(level, i+1, j+1)
            local horizontal_passage = gen.is_floor(level, i, j) and 
                                       gen.is_floor(level, i-1, j) and 
                                       gen.is_floor(level, i+1, j) and 
                                       not gen.is_trap_at(level, i, j) and
                                       not gen.is_trap_at(level, i-1, j) and
                                       not gen.is_trap_at(level, i+1, j) and
                                       gen.is_wall(level, i, j-1) and
                                       gen.is_wall(level, i, j+1) and
                                       gen.is_wall(level, i-1, j-1) and
                                       gen.is_wall(level, i-1, j+1) and
                                       gen.is_wall(level, i+1, j-1) and
                                       gen.is_wall(level, i+1, j+1)
            if vertical_passage and math.random() < probability then
                local trap = {
                    class = 'cls.trap.swinging',
                    args = {i, j, 0},
                    temp_obj = require('cls.trap.swinging').new(i, j, 0),
                }
                table.insert(level.traps, trap)
            elseif horizontal_passage and math.random() < probability then
                local trap = {
                    class = 'cls.trap.swinging',
                    args = {i, j, 1},
                    temp_obj = require('cls.trap.swinging').new(i, j, 1),
                }
                table.insert(level.traps, trap)
            end
        end
    end
end

function gen.create_arrow_traps(level)
    local probability = 0.05
    local min_distance_from_exit = 3
    for j, row in pairs(level.tiles) do
        for i, t in pairs(row) do
            if gen.is_floor(level, i, j) and math.random() < probability then
                gen.create_arrow_trap(level, i, j)
            end
        end
    end
end

function gen.create_arrow_trap(level, trap_x, trap_y)
    local direction = math.random(4)
    local distance = 0
    local dx, dy = 0, 0
    if direction == 1 then
        dx = 1
    elseif direction == 2 then
        dy = 1
    elseif direction == 3 then
        dx = -1
    elseif direction == 4 then
        dy = -1
    end
    local arrow_x, arrow_y = trap_x + dx, trap_y + dy
    while gen.is_floor(level, arrow_x, arrow_y) do
        arrow_x = arrow_x + dx
        arrow_y = arrow_y + dy
        distance = distance + 1
    end

    local fake_wall = gen.get_tile(level, arrow_x, arrow_y) == TILE.FAKE_WALL
    if fake_wall then
        return 
    end

    local too_close = math.abs(arrow_x - trap_x) + math.abs(arrow_y - trap_y) < 3
    if too_close then
        return
    end

    local min_distance_from_exit = 3
    local too_near_exit = math.abs(trap_y - level.start_position.y) + math.abs(trap_x - level.start_position.x) < min_distance_from_exit or 
                          math.abs(trap_y - level.start_position.y) + math.abs(trap_x - level.start_position.x) < min_distance_from_exit or
                          math.abs(arrow_y - level.end_position.y)  + math.abs(arrow_x - level.end_position.x)  < min_distance_from_exit or
                          math.abs(arrow_y - level.end_position.y)  + math.abs(arrow_x - level.end_position.x)  < min_distance_from_exit
    if too_near_exit then
        return
    end

    local occupied = gen.is_trap_at(level, trap_x, trap_y) or gen.is_trap_at(level, arrow_x, arrow_y)
    if occupied then
        return
    end

    local trap = {
        class = 'cls.trap.arrow',
        args = {trap_x, trap_y, arrow_x, arrow_y},
        temp_obj = require('cls.trap.arrow').new(trap_x, trap_y, arrow_x, arrow_y),
    }
    table.insert(level.traps, trap)
end

function gen.create_enemies(level)
    gen.update_status("Adding enemies...")
    
    -- TODO: Add random enemies (based on room size?)
    -- TODO: Add boss in boss room
end

function gen.create_treasure(level)
    gen.update_status("Adding treasure...")
end


function gen.finalise(level)
    for _, trap in pairs(level.traps) do
        trap.temp_obj = nil
    end
end


local level = gen.generate()

love.thread.getChannel("level-gen"):supply(level)
