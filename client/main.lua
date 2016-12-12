package.path = './?.lua;' .. './libs/?.lua;' .. './assets/sprites/?.lua;' .. package.path

function love.load()
	math.randomseed(os.time())
	binser = require 'libs/binser'
    vector = require "libs/vector"
	Camera = require 'libs/camera'
    Timer = require "libs/timer"
	GamestateManager = require "libs/gamestate"
	settings = require("settings")
	constants = require("constants")
	require("util")
	require("error")
	require("network")
	require("game")

    user_alive = false
	settings.username = random_string(8)
	GamestateManager.registerEvents()
	GamestateManager.switch(game)
end

function love.update(dt)
end

function love.draw()
end

function love.quit()
	disconnect("Client closed by user")
end

function love.keypressed(key, scancode, isrepeat)
	if key == "f1" then
		settings.debug = not settings.debug
    elseif key == "f2" then
        debug.debug()
	elseif key == "escape" then
		love.event.quit()
	end
end
