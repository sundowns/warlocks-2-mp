function love.load()
	math.randomseed(os.time())
	binser = require "libs.binser"
    md5 = require "libs.md5"
    vector = require "libs.vector"
	Camera = require "libs.camera"
    Timer = require "libs.timer"
	GamestateManager = require "libs.gamestate"
    Class = require "libs.class"
    HC = require "libs.HC"
    suit = require 'libs.suit'
    require("src.util")
    settings = require("src.settings")
	constants = require("src.constants")
	require("src.error_screen")
	require("src.network")
	require("src.game")
    require("src.loading")
    require("src.menu")

    user_alive = false
	GamestateManager.registerEvents()
    GamestateManager.switch(menu)
end

function love.update(dt)
end

function love.draw()
end

function love.quit()
    if connected then
        disconnect("Client closed by user")
    end
end

function love.keypressed(key, scancode, isrepeat)
	if key == "f1" then
		settings.debug = not settings.debug
    elseif key == "f2" then
        settings.show_resource_info = not settings.show_resource_info
    elseif key == "f3" then
        settings.show_warnings = not settings.show_warnings
	elseif key == "escape" then
		love.event.quit()
    elseif key == "f10"then
        love.event.quit("restart")
    else
        suit.keypressed(key)
	end
end

function love.textinput(t)
    forwardTextInputToMenu(t)
end
