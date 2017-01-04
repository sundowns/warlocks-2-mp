function love.load()
	math.randomseed(os.time())
	binser = require "libs.binser"
    vector = require "libs.vector"
	Camera = require "libs.camera"
    Timer = require "libs.timer"
	GamestateManager = require "libs.gamestate"
    Class = require "libs.class"
    HC = require "libs.HC"
    require("util")
    settings = require("settings")
	constants = require("constants")
	require("error_screen")
	require("network")
	require("game")
    require("loading")
    require("menu")

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
        debug.debug()
    elseif key == "f5" then
        os.execute("cls")
        print("\n")
	elseif key == "escape" then
		love.event.quit()
    else
        suit.keypressed(key)
	end
end

function love.textinput(t)
    suit.textinput(t)
end
