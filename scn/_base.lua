local scene = {}
scene.__index = scene
function scene:__tostring()
    return "scene " .. self.name
end

function scene.new(name)
    local self = {}
    setmetatable(self, scene)
    self.name = name
    return self
end

function scene:load()
end

function scene:update(dt, mx, my)
end

function scene:draw()
end

function scene:close()
end

return scene
