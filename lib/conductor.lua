local conductor = {
    _VERSION     = 'v0.0.1',
    _DESCRIPTION = 'A Lua Scene Management library for LÖVE games',
    _URL         = '',
    _LICENSE     = [[
        MIT License

        Copyright (c) 2021 Huw Taylor

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]]
}

function conductor.hook()
    for event_name, func in pairs(love.handlers) do
        love.handlers[event_name] = function(...)
            func(...)
            if conductor[event_name] then
                conductor[event_name](...)
            end
        end
    end
end

local current_scene = nil
local scene_stack = {}
local quit_on_no_scene = false

local function closeScene()
    if current_scene then
        current_scene:close()
    end
end

local function loadScene()
    if current_scene then
        current_scene:load()
    end
end

function conductor.quitWithoutScene()
    quit_on_no_scene = true
end

function conductor.persistWithoutScene()
    quit_on_no_scene = false
end

function conductor.scene()
    return current_scene
end

function conductor.peekScene()
    return scene_stack[#scene_stack]
end

function conductor.clearTo(new_scene)
    while current_scene do
        conductor.popScene()
    end
    conductor.pushScene(new_scene)
end

function conductor.setScene(new_scene)
    closeScene()
    current_scene = new_scene
    loadScene()
end

function conductor.pushScene(new_scene)
    table.insert(scene_stack, current_scene)
    current_scene = new_scene
    loadScene()
end

function conductor.popScene(n)
    for i = 1, (n or 1) do
        closeScene()
        current_scene = table.remove(scene_stack)
        if quit_on_no_scene and current_scene == nil then
            love.event.quit()
        end
    end
end

------------------------------------------------
-- Methods to pass along to relevant scene(s) --
------------------------------------------------
function conductor.keypressed(key, is_repeat)
    if current_scene and current_scene.keyPressed then 
        current_scene:keyPressed(key, is_repeat)
    end
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundKeypressed and scene ~= current_scene then
            scene:backgroundKeyPressed(key, is_repeat)
        end
    end
end

function conductor.textinput(text)
    if current_scene and current_scene.keyTyped then
        current_scene:keyTyped(text)
    end
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundKeyTyped and scene ~= current_scene then
            scene:backgroundKeyTyped(text)
        end
    end
end

function conductor.mousepressed(mx, my, key)
    if current_scene and current_scene.mousePressed then
        current_scene:mousePressed(mx, my, key)
    end
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundMousePressed and scene ~= current_scene then
            scene:backgroundMousePressed(mx, my, key)
        end
    end
end

function conductor.mousereleased(mx, my, key)
    if current_scene and current_scene.mouseReleased then
        current_scene:mouseReleased(mx, my, key)
    end
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundMouseReleased and scene ~= current_scene then
            scene:backgroundMouseReleased(mx, my, key)
        end
    end
end

function conductor.wheelmoved(dx, dy)
    local mx, my = love.mouse.getPosition()
    if current_scene and current_scene.mouseScrolled then
        current_scene:mouseScrolled(mx, my, dx, dy)
    end
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundMouseScrolled and scene ~= current_scene then
            scene:backgroundMouseScrolled(mx, my, dx, dy)
        end
    end
end

function conductor.update(dt)
    local mx, my = love.mouse.getPosition()
    if current_scene and current_scene.update then
        current_scene:update(dt, mx, my)
    end
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundUpdate and scene ~= current_scene then
            scene:backgroundUpdate(dt, mx, my)
        end
    end
end

function conductor.draw()
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundDraw and scene ~= current_scene then
            scene:backgroundDraw()
        end
    end
    if current_scene and current_scene.draw then
        current_scene:draw()
    end
end

return conductor
