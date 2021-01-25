if not math.clamp then
    function math.clamp(x, lower, upper)
      return x < lower and lower or (x > upper and upper or x)
    end
end

local camera = {}
camera.__index = camera

function camera.new()
    local this = {}
    setmetatable(this, camera)
    this.x = 0
    this.y = 0
    this.scaleX = 1
    this.scaleY = 1
    this.rotation = 0
    return this
end

function camera:set()
    love.graphics.push()
    love.graphics.rotate(-self.rotation)
    love.graphics.scale(self.scaleX, self.scaleY)
    love.graphics.translate(-self.x, -self.y)
end

function camera:unset()
    love.graphics.pop()
end

function camera:move(dx, dy)
    self:setX(self.x + (dx or 0))
    self:setY(self.y + (dy or 0))
end

function camera:rotate(dr)
    self.rotation = self.rotation + dr
end

function camera:scale(sx, sy)
    sx = sx or 1
    self.scaleX = self.scaleX * sx
    self.scaleY = self.scaleY * (sy or sx)
end

function camera:setX(value)
    if self.bounds then
        self.x = math.clamp(value, self.bounds.x1, self.bounds.x2)
    else
        self.x = value
    end
end

function camera:setY(value)
    if self.bounds then
        self.y = math.clamp(value, self.bounds.y1, self.bounds.y2)
    else
        self.y = value
    end
end

function camera:setPosition(x, y)
    if x then self:setX(x) end
    if y then self:setY(y) end
end

function camera:centreOn(x, y)
    local viewWidth = love.graphics.getWidth() / self.scaleX
    local viewHeight = love.graphics.getHeight() / self.scaleY
    self:setPosition(x - viewWidth / 2, y - viewHeight / 2)
end

function camera:setScale(sx, sy)
    sx = sx or 1
    self.scaleX = sx
    self.scaleY = sy or sx
end

function camera:setRotation(r)
    self.rotation = r
end

function camera:getBounds()
    return unpack(self.bounds)
end

function camera:setBounds(x1, y1, x2, y2)
    self.bounds = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

function camera:toWorldPosition(screenX, screenY)
    -- TODO: include rotation
    return (screenX / self.scaleX + self.x), (screenY / self.scaleY + self.y)
end

function camera:toScreenPosition(worldX, worldY)
    -- TODO: include rotation
    return (worldX - self.x) * math.abs(self.scaleX), (worldY - self.y) * self.scaleY
end

return camera
