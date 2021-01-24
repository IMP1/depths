local level = require 'cls.level.level'

local map = nil
local map_generator = nil
map_generator_status = "Pending"

function love.load()
    map_generator = level.generate({
        min_width  = 24,
        min_height = 24,
        max_width  = 32,
        max_height = 32,
        seed = os.time(),
    })
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

function love.draw()
    love.graphics.setColor(1, 1, 1)
    if map then
        love.graphics.push()
        love.graphics.translate(100, 100)
        map:draw()
        love.graphics.pop()
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(map.seed, 0, 0)
    end
    if not map then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(map_generator_status)
    end
end