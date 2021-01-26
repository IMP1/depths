local Vector_mt = {}
local Vector = {}
setmetatable(Vector, Vector_mt)
Vector.__index = Vector

-- CONSTRUCTOR
--------------
function Vector.new(x, y)
    local self = {}
    setmetatable(self, Vector)
    self.data = {x, y}
    return self
end

function Vector_mt:__call(x, y)
    return Vector.new(x, y)
end

-- DUPLICATE
function Vector:copy()
    return Vector.new(unpack(self.data))
end

-- NEGATION
-----------
function Vector:__unm()
    local outcome = self:copy()
    for i, _ in pairs(self.data) do
        outcome.data[i] = -self[i]
    end
    return outcome
end

-- MAP
------
local function map(self, func, obj)
    local outcome = self:copy()
    for i, _ in pairs(self.data) do
        outcome.data[i] = func(self, obj, i)
    end
    return outcome
end

-- ADDITION
-----------
function Vector:__add(obj)
    assert( getmetatable(obj) == Vector, "Argument must be a vector" )
    return map(self, function(self, obj, i) return self[i] + obj[i] end, obj)
end

-- SUBTRACTION
--------------
function Vector:__sub(obj)
    return self + -obj
end

-- CROSS PRODUCT
----------------
-- function Vector:cross(obj)
--     assert( getmetatable(obj) == Vector, "Argument must be a vector" )
--     return Vector.new( self[2]*obj[3] - self[3]*obj[2], 
--                         self[3]*obj[1] - self[1]*obj[3], 
--                         self[1]*obj[2] - self[2]*obj[1])
-- end

-- COMPONENT-WISE MULTIPLICATION
--------------------------------
function Vector:__mul(obj)
    assert( getmetatable(obj) == Vector or type(obj) == "number", "Argument must either be a vector or a number" )
    if type(obj) == "number" then
        return map(self, function(self, obj, i) return self[i] * obj end, obj)
    elseif getmetatable(obj) == Vector then
        return map(self, function(self, obj, i) return self[i] * obj[i] end, obj)
    end
end

-- COMPONENT-WISE DIVISION
--------------------------
function Vector:__div(obj)
    assert( getmetatable(obj) == Vector or type(obj) == "number", "Argument must either be a vector or a number" )
    if type(obj) == "number" then
        return map(self, function(self, obj, i) return self[i] / obj end, obj)
    elseif getmetatable(obj) == Vector then
        return map(self, function(self, obj, i) return self[i] / obj[i] end, obj)
    end
end

-- DOT PRODUCT
--------------
function Vector:dot(obj)
    assert( getmetatable(obj) == Vector, "Argument must be a vector" )
    local outcome = 0
    for i, _ in pairs(self.data) do
        outcome = outcome + (self.data[i] * obj[i])
    end
    return outcome
end

local function isSwizzle(i)
    return type(i) == "string" and (i == i:match("[xy]+"))
end

local function getSwizzle(i)
    if i == "x" then return 1 end
    if i == "y" then return 2 end
    local swizzle = {}
    for letter in i:gmatch(".") do
        table.insert(swizzle, getSwizzle(letter))
    end
    return swizzle
end

-- INTUITIVE DATA ACCCESS
-------------------------
function Vector:__index(i)
    if isSwizzle(i) then
        i = getSwizzle(i)
        if type(i) == "table" then
            local data = {}
            for _, index in pairs(i) do
                table.insert(data, self.data[index])
            end
            return Vector.new(unpack(data))
        end
    end
    if type(i) == "number" then
        return self.data[i]
    else
        return Vector[i]
    end
end

-- INTUITIVE DATA MUTATING
--------------------------
function Vector:__newindex(i, value)
    if i == "x" then i = 1 end
    if i == "y" then i = 2 end
    if type(i) == "number" then
        rawset(self.data, i, value)
    else
        rawset(self, i, value)
    end
end

-- STRING REPRESENTATION
------------------------
function Vector:__tostring()
    output = "("
    for i, n in pairs(self.data) do
        output = output .. n
        if i < #self.data then
            output = output .. ", "
        end
    end
    return output .. ")"
end

-- MAGNITUDE
------------
function Vector:magnitude()
    return math.sqrt(self:magnitudeSquared())
end

function Vector:magnitudeSquared()
    local n = 0
    for k, v in pairs(self.data) do
        n = n + v^2
    end
    return n
end

-- UNIT VECTOR
--------------
function Vector:normalise()
    local size = self:magnitude()
    local data = {}
    for i, val in ipairs(self.data) do
        data[i] = val / size
    end
    return Vector.new(unpack(data))
end

-- MATRIX ROTATION SHORTCUT
-- ---------------------------
-- function Vector:rotate(a, b, c)
--     local outcome = self:copy()
    
--     local x, y, z
--     -- x-axis
--     y, z = self.y, self.z
--     outcome.y = y * math.cos(a) + z * math.sin(a)
--     outcome.z = z * math.cos(a) - y * math.sin(a)
--     -- y-axis
--     x, z = self.x, self.z
--     outcome.x = x * math.cos(b) - z * math.sin(b)
--     outcome.z = z * math.cos(b) + x * math.sin(b)
--     -- z-axis
--     x, y = self.x, self.y
--     outcome.x = x * math.cos(c) + y * math.sin(c)
--     outcome.y = y * math.cos(c) - x * math.sin(c)
   
--     return outcome
-- end

-- ANGLE BETWEEN VECTORS
------------------------
function Vector.angleBetween(vect1, vect2)
    return math.acos( Vector.dot(vect1, vect2) / (vect1:magnitude() * vect2:magnitude()) )
end

-- PERPENDICLUAR TO VECTORS
---------------------------
function Vector.normal(vect1, vect2)
    return Vector.cross(vect1, vect2):normalise()
end

return Vector
