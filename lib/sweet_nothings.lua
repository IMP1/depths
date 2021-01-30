local sweet_nothings = {
    _VERSION     = 'v0.0.1',
    _DESCRIPTION = 'A Lua localisation library for LÖVE games',
    _URL         = '',
    _LICENSE     = [[
        MIT License

        Copyright (c) 2017 Huw Taylor

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

sweet_nothings.actions = {
    ERROR        = "error",
    IGNORE       = "ignore",
    RETURN_BLANK = "blank",
    RETURN_NIL   = "nil",
}

sweet_nothings.settings = {
    -- BLANK, ERROR, IGNORE, NIL
    onMissingLocalisation   = sweet_nothings.actions.IGNORE,
    addMissingLocalisations = true,
    -- BLANK, ERROR, IGNORE, NIL
    onUnsetLanguage         = sweet_nothings.actions.ERROR,
    -- ERROR, IGNORE
    onMissingLanguageFile   = sweet_nothings.actions.IGNORE,
    addMissingLanguageFiles = false,
}

local currentLanguage = nil
local languageFilesPath = "lang"
local lookupTable = {}

local function addString(newString)
    -- TODO: Make sure string doesn't already exist.
    local files = love.filesystem.getDirectoryItems(languageFilesPath)
    for _, file in pairs(files) do
        local path = languageFilesPath .. "/" .. file
        local fileString = love.filesystem.read(path)
        local index = fileString:find("}[^}]*$")
        local newString = newString:gsub("\n", "\\n")
        local newContent = fileString:sub(1, index - 1) ..
                           "    [\"" .. newString .. "\"] = \"" .. newString .. "\", -- AUTOMATICALLY ADDED.\n" ..
                           fileString:sub(index)
        love.filesystem.write(path, newContent)
    end
end

function sweet_nothings.internationalise(string)
    -- TODO: Make a record of the text to translate. Make sure each localisation file has a translation for this text.
    local text = {
        original_text = string,
        original_language = currentLanguage,
    }
    setmetatable(text, {
        __tostring = function(self)
            -- TODO: Have a tostring for the text table that returns it localised into current language down the line.
            return sweet_nothings.localise(self.original_text)
        end
    })
    return text
end

function sweet_nothings.hook()
    -- TODO: Tidy this up. 
    -- TODO: Add other functions that deal with text. Like the font functions. 
    --       Or a warning that this is unsopported (because they're usertypes and so can't be extended)
    --       Or a message that this happens automatically (test Text and Font objects to see if they perform `tostring`)
    local text_functions = {
        {love.graphics, "print"},
        {love.graphics, "printf"},
    }
    for _, text_function in pairs(text_functions) do
        local obj, func = unpack(text_function)
        local old_func = obj[func]
        obj[func] = function(text, ...)
            return old_func(tostring(text), ...)
        end
    end
end

function sweet_nothings.localise(text)
    if not currentLanguage then
        if sweet_nothings.settings.onUnsetLanguage == sweet_nothings.actions.RETURN_BLANK then
            return ""
        elseif sweet_nothings.settings.onUnsetLanguage == sweet_nothings.actions.ERROR then
            error("There is no language set. Use sweet_nothings.setLanguage() to set which language to use.")
        elseif sweet_nothings.settings.onUnsetLanguage == sweet_nothings.actions.IGNORE then
            return text
        elseif sweet_nothings.settings.onUnsetLanguage == sweet_nothings.actions.RETURN_NIL then
            return nil
        end
    else
        if lookupTable[text] then
            return lookupTable[text]
        else
            if sweet_nothings.settings.addMissingLocalisations then
                addString(text)
                local path = languageFilesPath .. "/" .. currentLanguage
                lookupTable = love.filesystem.load(path)()
            end
            if sweet_nothings.settings.onMissingLocalisation == sweet_nothings.actions.RETURN_BLANK then
                return ""
            elseif sweet_nothings.settings.onMissingLocalisation == sweet_nothings.actions.ERROR then
                error("Missing localisation for '" .. text .. "' in " .. currentLanguage .. ".")
            elseif sweet_nothings.settings.onMissingLocalisation == sweet_nothings.actions.IGNORE then
                return text
            elseif sweet_nothings.settings.onMissingLocalisation == sweet_nothings.actions.RETURN_NIL then
                return nil
            end
        end
    end
end

function sweet_nothings.deferredLocalise(text)
    return function()
        return sweet_nothings.localise(text)
    end
end

function sweet_nothings.setLanguage(languageCode)
    local path = languageFilesPath .. "/" .. languageCode
    local exists = love.filesystem.getInfo(path)
    if exists then
        lookupTable = love.filesystem.load(path)()
    else
        if sweet_nothings.settings.addMissingLanguageFiles then
            local empty_lookup = "return {\n\n}\n"
            local success, error_message = love.filesystem.write(path, empty_lookup)
            -- local f = love.filesystem.newFile(path)
            -- ok, err = f:open('w')
            if error_message then error(error_message) end
            print(love.filesystem.getRealDirectory(path))
        end
        if sweet_nothings.settings.onMissingLanguageFile == sweet_nothings.actions.ERROR then
            error("Missing language file '" .. languageCode .. "'.")
        elseif sweet_nothings.settings.onMissingLanguageFile == sweet_nothings.actions.IGNORE then
            lookupTable = lookupTable or {}
        end
    end
    currentLanguage = languageCode
    for k, v in pairs(lookupTable) do
        print(k, v)
    end
end

function sweet_nothings.getLanguage()
    return currentLanguage
end

function sweet_nothings.setLanguagesFolder(path)
    languageFilesPath = path
    love.filesystem.createDirectory(languageFilesPath)
end

function sweet_nothings.getLanguagesFolder(path)
    return languageFilesPath
end

return sweet_nothings
