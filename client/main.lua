package.path = './?.lua;' .. './libs/?.lua;' .. package.path

debug = false
client_version = "0.0.1"

username = ""
user_alive = false
tick = 0
tickrate = 0.015625
updateRate = tickrate*8
updateTimer = tickrate*8
tick_timer = 0

function love.load()
	math.randomseed(os.time())
	require("util")
	require("network")
	require("world")
	require("player")
	json = require("json")
	Camera = require 'libs/camera'

	love.graphics.setNewFont("assets/misc/IndieFlower.ttf", defaultFontSize)

	username = random_string(8)
	net_initialise()

end

function love.update(dt)
	worldTime = worldTime + dt
	tick_timer = tick_timer + dt

	-- if dt < 1/60 then -- 60 fps limit
	-- 	love.timer.sleep(1/60 - dt)
	-- end

	if tick_timer > tickrate then
		print("tick")
		tick = tick + 1
		tick_timer = tick_timer - tickrate

		if connected and user_alive and tick%4 == 0 then
			--print(tick)
	   	table.insert(player_state_buffer, player)
	   	if #player_state_buffer > 64 then
	   		local last = table.remove(player_state_buffer)
	   		--print("last x: ".. last.x .. " last y: " .. last.y)
	   	end
	 	end

	 	if user_alive then
			process_input()
			calculate_player_movement(dt)
			updateCamera()
			--print("curr x: " .. player.x .. " y: " .. player.y)
		end

		if updateTimer > updateRate then
			if user_alive then
				send_player_update(player, username)
			end
			updateTimer = updateTimer-updateRate
		end

		repeat
			event = listen()
			if event and event.type == "receive" then
				print("receiving packet")
				--ent, cmd, params = data:match("^(%w+)%p(%w+)%p(.*)")
				payload = json.decode(event.data)
				if payload.cmd == "ENTITYAT" then --need to add velocity here so we can interpolate movement on client
					--print("debug: "..event.data)
					assert(payload.x and payload.y and payload.entity_type)
					x, y = tonumber(payload.x), tonumber(payload.y)
					if world[payload.alias] == nil then
						add_entity(payload.alias, payload.entity_type, {name = payload.alias, colour = payload.colour or nil})
					else
					--print("pload: " ..payload.alias .. " playa: " .. player.name)
						if payload.alias ~= player.name then
							world[payload.alias].x = round_to_nth_decimal(x, 2)
							world[payload.alias].y = round_to_nth_decimal(y, 2)
						end

					end
				elseif payload.cmd == 'ENTITYDESTROY' then
					remove_entity(payload.alias, payload.entity_type)
				elseif payload.cmd == 'SERVERERROR' then
					print(payload.msg)
				elseif payload.cmd == 'JOINACCEPTED' then
					confirm_join()
					print(data)
					tick = payload.server_tick
					prepare_player(username, payload.colour)
					prepare_camera()
				else
					print(event.data)
					print("unrecognised command:", payload.cmd)
				end
			elseif event and event.type == "connect" then
				print("connect msg received")
				--error("Network error: " .. tostring(msg))
			elseif event and event.type == "disconnect" then
				disconnect("Server disconnected")
				--print("disconnect msg received")
			else
				--print("No packets waiting...")
			end
		until not event
	end
end

function love.draw()
	if user_alive then camera:attach() end
	love.graphics.setColor(255, 128, 128)
	love.graphics.circle( "fill", 0, 0, 150, 100 )
	reset_colour()
	for k, entity in pairs(world) do
		if entity.entity_type == "PLAYER" then
			love.graphics.draw(get_player_img(player), entity.x, entity.y)
		elseif entity.entity_type == "ENEMY" then
			local enemy = world[k]
			love.graphics.draw(get_enemy_img(enemy), enemy.x, enemy.y)
		end
	end

	if debug then
		local camX, camY = camera:position()
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.circle('fill', camX, camY, 2, 16)
		love.graphics.rectangle('line', camX - love.graphics.getWidth()*0.05, camY - love.graphics.getHeight()*0.035, 0.1*love.graphics.getWidth(), 0.07*love.graphics.getHeight())
		reset_colour()
	end
	if user_alive then camera:detach() end
end

function love.quit()
	disconnect("Client closed by user")
end

function love.keypressed(key, scancode, isrepeat)
	if key == "f1" then
		debug = not debug
	elseif key == "escape" then
		love.event.quit()
	end
end

function prepare_camera()
	camera = Camera(player.x, player.y)
	camera:zoom(1.25)
end

function updateCamera()
	local camX, camY = camera:position()
	local newX, newY = camX, camY
	if (player.x > camX + love.graphics.getWidth()*0.05) then
		newX = player.x - love.graphics.getWidth()*0.05
	end
	if (player.x < camX - love.graphics.getWidth()*0.05) then
		newX = player.x + love.graphics.getWidth()*0.05
	end
	if (player.y > camY + love.graphics.getHeight()*0.035) then
		newY = player.y - love.graphics.getHeight()*0.035
	end
	if (player.y < camY - love.graphics.getHeight()*0.035) then
		newY = player.y + love.graphics.getHeight()*0.035
	end

	--camera:lookAt(newX, newY)
	camera:lockPosition(newX, newY, camera.smooth.damped(1))
end
