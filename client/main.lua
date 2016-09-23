package.path = './?.lua;' .. './libs/?.lua;' .. './assets/*;' .. package.path

user_alive = false
tick = 0
tick_timer = 0

function love.load()
	math.randomseed(os.time())
	json = require("json")
	Camera = require 'libs/camera'
	GamestateManager = require "libs/gamestate"
	settings = require("settings")
	constants = require("constants")
	require("util")
	require("error")
	require("network")
	require("game")

	settings.username = random_string(8)
	love.graphics.setNewFont("assets/misc/IndieFlower.ttf", defaultFontSize)
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
	elseif key == "escape" then
		love.event.quit()
	elseif key == "f3" then
		local a = ""
		if player.dash.ready then a = " dash ready" end
		print(player.state .. " | dash_ready: " .. a)
	end
end
