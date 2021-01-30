local settings = {}

local SETTINGS_FILENAME = "settings"

local user_settings = {}

function stringify(value, depth) -- TODO: Make this local
    depth = depth or 0
    if type(value) == "string" then
        value = value:gsub("\"", "\\\"")
        -- TODO: Escape other characters? `\n`, `\t`, ...
        return "\"" .. value .. "\""
    elseif type(value) == "table" then
        local outer_padding = string.rep("\t", depth)
        local inner_padding = string.rep("\t", depth + 1)
        local str = "{\n"
        for k, v in pairs(value) do
            str = str .. inner_padding .. "[" .. stringify(k) .. "] = " .. stringify(v, depth+1) .. ",\n"
        end
        return str .. outer_padding .. "}"
    else
        return tostring(value)
    end
end

function settings.load()
    if love.filesystem.getInfo(SETTINGS_FILENAME) then
        user_settings = love.filesystem.load(SETTINGS_FILENAME)()
    end
end

function settings.save()
    local settings_string = "return " .. stringify(user_settings) .. "\n"
    love.filesystem.write(SETTINGS_FILENAME, settings_string)
end

function settings.get(key)
    return user_settings[key]
end

function settings.set(key, value)
    user_settings[key] = value
end

function settings.setDefaults(defaults)
    for key, default in pairs(defaults) do
        if user_settings[key] == nil then
            user_settings[key] = default
        end
    end
end

return settings