local animation = {}
animation.__index = animation

function animation.new(options)
    local self = {}
    setmetatable(self, animation)

    self.image           = options.image
    self.frame_durations = options.frame_durations or options.frame_duration
    self.frame_count     = options.frames          or 0
    self.looping         = options.loop

    self.quads = {}
    self.width = self.image:getWidth() / options.frames_wide
    self.height = self.image:getHeight() / options.frames_high
    for n = 1, self.frame_count do
        local x = ((n-1) % options.frames_wide) * self.width
        local y = math.floor((n-1) / options.frames_wide) * self.height
        table.insert(self.quads, love.graphics.newQuad(x, y, self.width, self.height, self.image:getWidth(), self.image:getHeight()))
    end

    self.current_frame = 0
    self.timer = 0
    self.started = false
    self.finished = false

    return self
end

local function frame_duration(self, frame_number)
    if type(self.frame_durations) == "number" then
        return self.frame_durations
    else
        return self.frame_durations[frame_number]
    end
end

function animation:reset()
    self.current_frame = 1
    self.timer = 0
    self.finished = false
    self.started = false
end

function animation:start()
    self.started = true
end

function animation:is_playing()
    return self.started and not self.finished
end

function animation:update(dt)
    if not self.started then return end
    if self.finished then return end
    self.timer = self.timer + dt
    if self.timer >= frame_duration(self, self.current_frame) then
        self.timer = self.timer - frame_duration(self, self.current_frame)
        self.current_frame = self.current_frame + 1
        if self.current_frame >= self.frame_count then
            if self.looping then
                self.current_frame = 1
            else
                self.current_frame = self.frame_count
                self.finished = true
            end
        end
    end
end

function animation:draw(...)
    local quad = self.quads[self.current_frame]
    love.graphics.draw(self.image, quad, ...)
end

return animation
