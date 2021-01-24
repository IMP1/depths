local options = love.thread.getChannel("level-gen"):demand()
local tile = love.thread.getChannel("level-gen"):demand()

local seed = options.seed or os.time()
math.randomseed(seed)

local MIN_WIDTH  = options.min_width  or 24
local MIN_HEIGHT = options.min_height or 24
local MAX_WIDTH  = options.max_width  or 32
local MAX_HEIGHT = options.max_height or 32


local level_generator = {}

local function update_status(message)
    love.thread.getChannel("level-gen-status"):push(message)
end

function level_generator.generate()
    local level = {}
    update_status("Pre-Setup")

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

    update_status("Generating...")

    level_generator.create_layout(level)
    level_generator.generate_auto_tiles(level)
    level_generator.add_traps(level)
    level_generator.add_enemies(level)
    level_generator.add_treasure(level)

    update_status("Finished.")
    return level
end

function level_generator.create_layout(level)
    level_generator.add_rooms(level)
    -- level_generator.add_corridors(level)
    -- level_generator.join_rooms(level)
    level_generator.fill_up(level)
    -- level_generator.hide_rooms(level)
    -- level_generator.add_columns(level)
    -- level_generator.ensure_wall_thickness(level)
end

local function get_tile(level, x, y)
    if level.tiles[y] and level.tiles[y][x] then
        return level.tiles[y][x]
    end
    return tile.NONE
end

local function is_wall(level, x, y)
    local t = get_tile(level, x, y)
    return t == tile.WALL_TOP or t == tile.WALL_SIDE
end

local function is_exit(level, x, y)
    if level.start_position.x == x and level.start_position.y == y then return true end
    if level.end_position.x == x and level.end_position.y == y then return true end
    return false
end

local function is_floor(level, x, y)
    local t = get_tile(level, x, y)
    return t == tile.FLOOR or t == tile.FLOOR_START or t == tile.FLOOR_END or t == tile.FLOOR_BOSS
end

local function set_tile(level, x, y, tile_type, ...)
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
    if x < 1 or x > level.width then return false end
    if y < 1 or y > level.height then return false end
    for _, room in pairs(level.rooms) do
        local overlap = true
        if (x > room.x + room.width or room.x > x + width) then
            overlap = false
        end
        if (y > room.y + room.height or room.y > y + height) then
            overlap = false
        end
        if overlap then return false end
    end
    return true
end

local function add_room(level, x, y, width, height, floor_type, wall_type)
    -- if wall_type then
        for j = y - 1, y + height + 1 do
            for i = x - 1, x + width + 1 do
                set_tile(level, i, j, wall_type or tile.WALL_TOP)
            end
        end
    -- end
    for j = y, y + height do
        for i = x, x + width do
            set_tile(level, i, j, floor_type or tile.FLOOR)
        end
    end
    local room = {x = x, y = y, width = width, height = height}
    table.insert(level.rooms, room)
    return room
end

local function add_random_room(level, width, height, tile_type)
    local random_pos = math.floor(math.random() * level.width * level.height)
    for n = random_pos, level.width * level.height do
        local x = n % level.width
        local y = math.floor(n / level.width)
        if is_space_at(level, x, y, width, height) then
            return add_room(level, x, y, width, height, tile_type)
        end
    end
    for n = random_pos, 1, -1 do
        local x = n % level.width
        local y = math.floor(n / level.width)
        if is_space_at(level, x, y, width, height) then
            return add_room(level, x, y, width, height, tile_type)
        end
    end
    return nil
end

function level_generator.add_rooms(level)
    update_status("Adding rooms...")
    local count = 0
    -- Add necessary rooms
    local incomplete = true
    while incomplete do
        local start_room = add_random_room(level, 4, 3, tile.FLOOR_START)
        local end_room = add_random_room(level, 4, 3, tile.FLOOR_END)
        local boss_room = add_random_room(level, 6, 5, tile.FLOOR_BOSS)
        if start_room and end_room and boss_room then
            local start_x = start_room.x + math.floor(math.random() * start_room.width)
            local end_x = end_room.x + math.floor(math.random() * end_room.width)
            local boss_x = boss_room.x + math.floor(math.random() * boss_room.width)
            local boss_y = boss_room.y + math.floor(math.random() * boss_room.height)
            level.start_position = {x = start_x, y = start_room.y - 1}
            level.end_position = {x = end_x, y = end_room.y - 1}
            level.boss_position = {x = boss_x, y = boss_y}
            incomplete = false
        end
        update_status("Failed " .. count .. " times...")
        count = count + 1
    end
    update_status("Adding rooms...")
    -- Add optional rooms
    local large_room_count = 3 + math.floor(math.random() * 4)
    for i = 1, large_room_count do
        local w = 4 + math.floor(math.random() * 4)
        local h = 3 + math.floor(math.random() * 4)
        local tile_type = tile.FLOOR
        if math.random() < 0.1 then tile_type = tile.WALL_TOP end
        add_random_room(level, w, h, tile_type)
    end
    local medium_room_count = 5 + math.floor(math.random() * 4)
    for i = 1, medium_room_count do
        local w = 3 + math.floor(math.random() * 3)
        local h = 2 + math.floor(math.random() * 5)
        local tile_type = tile.FLOOR
        if math.random() < 0.1 then tile_type = tile.WALL_TOP end
        add_random_room(level, w, h, tile_type)
    end
    local small_room_count = 7 + math.floor(math.random() * 4)
    for i = 1, small_room_count do
        local w = 2 + math.floor(math.random() * 2)
        local h = 2 + math.floor(math.random() * 2)
        local tile_type = tile.FLOOR
        if math.random() < 0.1 then tile_type = tile.WALL_TOP end
        add_random_room(level, w, h, tile_type)
    end
end

function level_generator.add_corridors(level)
    update_status("Adding corridors...")
    for i = 1, 3 do
        local w = 6 + math.floor(math.random() * 3)
        local h = 1
        add_random_room(level, w, h, tile.FLOOR)
    end
    for i = 1, 3 do
        local w = 1
        local h = 6 + math.floor(math.random() * 3)
        add_random_room(level, w, h, tile.FLOOR)
    end
    for i = 1, 4 do
        local w = 4 + math.floor(math.random() * 3)
        local h = 1
        add_random_room(level, w, h, tile.FLOOR)
    end
    for i = 1, 4 do
        local w = 1
        local h = 4 + math.floor(math.random() * 3)
        add_random_room(level, w, h, tile.FLOOR)
    end
end

function level_generator.join_rooms(level)
    update_status("Joining rooms...")
    for j, row in pairs(level.tiles) do
        for i, t in pairs(row) do
            local wall_square = is_wall(level, i, j) and not is_exit(level, i, j) and
                                is_wall(level, i+1, j) and not is_exit(level, i+1, j) and 
                                is_wall(level, i, j+1) and not is_exit(level, i, j+1) and 
                                is_wall(level, i+1, j+1) and not is_exit(level, i+1, j+1)
            local passage_horz = is_floor(level, i-1, j) and is_floor(level, i+2, j) and
                                 is_floor(level, i-1, j+1) and is_floor(level, i+2, j+1)
            local passage_vert = is_floor(level, i, j-1) and is_floor(level, i, j+2) and
                                 is_floor(level, i+1, j-1) and is_floor(level, i+1, j+2)
            if wall_square and (passage_horz or passage_vert) then
                set_tile(level, i, j, tile.FLOOR)
                set_tile(level, i+1, j, tile.FLOOR)
                set_tile(level, i, j+1, tile.FLOOR)
                set_tile(level, i+1, j+1, tile.FLOOR)
            end
        end
    end
    for j, row in pairs(level.tiles) do
        for i, t in pairs(row) do
            local passage_horz = is_wall(level, i, j) and is_wall(level, i, j-1) and is_wall(level, i, j+1) and
                                 is_wall(level, i+1, j) and is_wall(level, i+1, j-1) and is_wall(level, i+1, j+1) and
                                 is_floor(level, i-1, j) and is_floor(level, i+2, j) and (
                                    is_wall(level, i-1, j-1) and is_wall(level, i-1, j+1) or
                                    is_wall(level, i+2, j-1) and is_wall(level, i+2, j+1) or
                                    is_wall(level, i-1, j-1) and is_wall(level, i+2, j+1) or
                                    is_wall(level, i+2, j-1) and is_wall(level, i-1, j+1)
                                )
            if passage_horz then
                set_tile(level, i, j, tile.FLOOR)
                set_tile(level, i+1, j, tile.FLOOR)
            end
        end
    end
    for j, row in pairs(level.tiles) do
        for i, t in pairs(row) do
            local passage_vert = is_wall(level, i, j) and is_wall(level, i-1, j) and is_wall(level, i+1, j) and
                                 is_wall(level, i, j+1) and is_wall(level, i-1, j+1) and is_wall(level, i+1, j+1) and
                                 is_floor(level, i, j-1) and is_floor(level, i, j+2) and (
                                    is_wall(level, i-1, j-1) and is_wall(level, i+1, j-1) or
                                    is_wall(level, i-1, j+2) and is_wall(level, i+1, j+2) or
                                    is_wall(level, i-1, j-1) and is_wall(level, i+1, j+2) or
                                    is_wall(level, i-1, j+2) and is_wall(level, i+1, j-1)
                                )
            if passage_vert then
                set_tile(level, i, j, tile.FLOOR)
                set_tile(level, i, j+1, tile.FLOOR)
            end
        end
    end
    update_status("Creating passages...")
    for j, row in pairs(level.tiles) do
        for i, t in pairs(row) do
            if is_wall(level, i, j) then
                level_generator.try_passage(level, i, j, 1, 0)
                level_generator.try_passage(level, i, j, 0, 1)
                level_generator.try_passage(level, i, j, -1, 0)
                level_generator.try_passage(level, i, j, 0, -1)
            end
        end
    end
end

local function check_for_passage(level, x, y, dx, dy, length)
    if x < 1 or x > level.width then return -1 end
    if y < 1 or y > level.height then return -1 end
    if is_exit(level, x + dx, y + dy) then return -1 end
    if is_wall(level, x + dx, y + dy) and is_floor(level, x + dx*2, y + dy*2) then
        return length or 0
    end
    if get_tile(level, x + dx, y + dy) == tile.NONE then
        return check_for_passage(level, x + dx, y + dy, dx, dy, (length or 0) + 1)
    end
    return -1
end

local function get_passage_width(level, x, y, dx, dy)
    local width = 1
    local adj_x = x + dy
    local adj_y = y + dx
    while check_for_passage(level, adj_x, adj_y, dx, dy) > 0 do
        width = width + 1
        adj_x = adj_x + dy
        adj_y = adj_y + dx
    end
    return width
end

local function make_passage(level, x, y, dx, dy, width, height)
    local ox, oy = x, y
    for j = y, y + height do
        for i = x, x + width do
            set_tile(level, i, j, tile.FLOOR, tile.WALL_TOP, tile.WALL_SIDE)
        end
    end
    repeat
        x = x + dx
        y = y + dy
        for j = y, y + height do
            for i = x, x + width do
                set_tile(level, i, j, tile.FLOOR, tile.WALL_TOP, tile.WALL_SIDE)
            end
        end
    until get_tile(level, x + dx, y + dy) == tile.NONE
    x = x + dx
    y = y + dy
    for j = y, y + height do
        for i = x, x + width do
            set_tile(level, i, j, tile.FLOOR, tile.WALL_TOP, tile.WALL_SIDE)
        end
    end
    local room = {x = x, y = y, width = x - ox + 1, height = y - oy + 1 }
    table.insert(level.rooms, room)
end

function level_generator.try_passage(level, x, y, dx, dy)
    if not is_floor(level, x - dx, y - dy) then
        return
    end
    local length = check_for_passage(level, x, y, dx, dy)
    if length > 0 then
        local width, height = 1, 1
        local passage_width = get_passage_width(level, x, y, dx, dy)
        if dx ~= 0 then
            height = passage_width
        end
        if dy ~= 0 then
            width = passage_width
        end
        make_passage(level, x, y, dx, dy, width, height)
    end
end

function level_generator.fill_up(level)
    update_status("Filling empty space...")
    for j = 1, level.height do
        for i = 1, level.width do
            if get_tile(level, i, j) == tile.NONE then
                set_tile(level, i, j, tile.WALL_TOP)
            end
        end
    end
end

function level_generator.hide_rooms(level)
    update_status("Hiding rooms...")
    local probability = 0.1
    for _, r in pairs(level.rooms) do
        if math.random() < probability then
            table.insert(level.hidden_rooms, r)
            for j = r.y - 1, r.y + r.height + 1 do
                if is_floor(level, r.x-1, j) and not is_exit(level, r.x-1, j-1) then
                    set_tile(level, r.x-1, j, tile.FAKE_WALL)
                end
                if is_floor(level, r.x+r.width, j) and not is_exit(level, r.x+r.width, j-1) then
                    set_tile(level, r.x+r.width, j, tile.FAKE_WALL)
                end
            end
            for i = r.x - 1, r.x + r.width + 1 do
                if is_floor(level, i, r.y-1) and not is_exit(level, i, r.y-1) and not is_exit(level, i, r.y-2) then
                    set_tile(level, i, r.y-1)
                    if is_wall(level, i-1, r.y) or is_wall(level, i+1, r.y) then
                        set_tile(level, i, r.y)
                    else
                        set_tile(level, i, r.y-2)
                    end
                end
                if is_floor(level, i, r.y+r.height) and not is_exit(level, i, r.y+r.height) and not is_exit(level, i, r.y+r.height-1) then
                    set_tile(level, i, r.y+r.height)
                    if is_wall(level, i-1, r.y+r.height) or is_wall(level, i+1, r.y+r.height) then
                        set_tile(level, i, r.y+r.height)
                    else
                        set_tile(level, i, r.y+r.height-1)
                    end
                end
            end
        end
    end
end

function level_generator.add_columns(level)
    update_status("Adding columns...")
end

function level_generator.ensure_wall_thickness(level)
end

function level_generator.generate_auto_tiles(level)
end

function level_generator.add_traps(level)
end

function level_generator.add_enemies(level)
end

function level_generator.add_treasure(level)
end




local level = level_generator.generate()

love.thread.getChannel("level-gen"):supply(level)
