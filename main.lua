local scene_manager = require 'lib.conductor'
local settings      = require 'lib.settings'
local safeword      = require 'lib.safeword'
local localisation  = require 'lib.sweet_nothings'

localisation.setLanguagesFolder("vocab")
localisation.settings.addMissingLanguageFiles = true -- TODO: Set to false before game is released
localisation.settings.addMissingLocalisations = true -- TODO: Set to false before game is released
localisation.settings.onUnsetLanguage = localisation.actions.ERROR

local DEFAULT_SETTINGS = {
    -- volume_master = 0.5,
    volume_master = 0,
    volume_music = 0.7,
    volume_sounds = 1,
    language = "en-gb",
    window_width = 960,
    window_height = 640,
    window_fullscreen = nil,
    window_vsync = 1,
}


scene_manager.hook()
localisation.hook()

T = localisation.internationalise

function love.load()
    settings.load()
    settings.setDefaults(DEFAULT_SETTINGS)
    safeword.load()

    love.audio.setVolume(settings.get("volume_master"))
    localisation.setLanguage(settings.get("language"))
    love.window.setMode(settings.get("window_width"), settings.get("window_height"), {
        fullscreen = not not settings.get("window_fullscreen"),
        fullscreentype = settings.get("window_fullscreen"),
        vsync = settings.get("window_vsync"),
    })

    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    local title_scene = require('scn.title')
    scene_manager.setScene(title_scene.new())
    scene_manager.quitWithoutScene()
end

function love.keypressed(key)
    
end

function love.threaderror(thread, error_message)
    error(error_message)
end

function love.update(dt)
    scene_manager.update(dt)
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    scene_manager.draw()
end

function love.quit()
    safeword.save()
end