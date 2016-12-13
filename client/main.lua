function love.load()
	math.randomseed(os.time())
	binser = require 'libs.binser'
    vector = require "libs.vector"
	Camera = require 'libs.camera'
    Timer = require "libs.timer"
	GamestateManager = require "libs.gamestate"
	settings = require("settings")
	constants = require("constants")
	require("util")
	require("error_screen")
	require("network")
	require("game")
    require("loading")
    require("menu")

    user_alive = false
	settings.username = random_string(8)
	GamestateManager.registerEvents()
    GamestateManager.switch(menu)
	--GamestateManager.switch(loading, "JOIN_GAME")
    --GamestateManager.switch(game)
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
	elseif key == "escape" then
		love.event.quit()
    else
        suit.keypressed(key)
	end
end

function love.textinput(t)
    suit.textinput(t)
end
