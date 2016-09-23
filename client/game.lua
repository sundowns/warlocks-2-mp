game = {} -- the game state


function game:enter(previous)
	require("world")
	require("player")
  love.graphics.setBackgroundColor(0,0,0)
	net_initialise()
	prepare_camera()
end

function game:update(dt)
	worldTime = worldTime + dt
	tick_timer = tick_timer + dt

	if user_alive then
		process_input(dt) ----------\ KEEP THESE TWO ONE AFTER THE OTHER
		update_player_movement(dt)--/ KEEP THESE TWO ONE AFTER THE OTHER
		update_camera()
		cooldowns(dt)
	end

	update_entities(dt)

	if tick_timer > constants.TICKRATE then -- THIS SHOULD BE USED FOR COMMUNCATION TO/FROM SERVER/KEEPING IN SYNC
		tick = tick + 1
		tick_timer = tick_timer - constants.TICKRATE

		if connected and user_alive and tick%4 == 0 then
	   	table.insert(player_state_buffer, player)
	   	if #player_state_buffer > 64 then
	   		local last = table.remove(player_state_buffer)
	   	end
	 	end

		if tick%netUpdateRate == 0 then
			if user_alive then
				send_player_update(player, settings.username)
			end

			repeat
				event = listen()
				if event and event.type == "receive" then
					payload = json.decode(event.data)
					dbg("receiving packet cmd: " ..payload.cmd)
					if payload.cmd == "ENTITYAT" then
						assert(payload.x and payload.y and payload.entity_type and payload.x_vel and payload.y_vel)
						x, y, x_vel, y_vel = tonumber(payload.x), tonumber(payload.y), tonumber(payload.x_vel), tonumber(payload.y_vel)
						if world[payload.alias] == nil then
							add_entity(payload.alias, payload.entity_type, {name = payload.alias, colour = payload.colour or nil, x=x, y=y, x_vel=x_vel, y_vel=y_vel})
						else
							if payload.alias ~= player.name then
								world[payload.alias].x = round_to_nth_decimal(x, 2)
								world[payload.alias].y = round_to_nth_decimal(y, 2)
								world[payload.alias].x_vel = round_to_nth_decimal(x_vel, 2)
								world[payload.alias].y_vel = round_to_nth_decimal(y_vel, 2)
							end
						end
					elseif payload.cmd == 'ENTITYDESTROY' then
						remove_entity(payload.alias, payload.entity_type)
					elseif payload.cmd == 'SERVERERROR' then
						disconnect("Connection closed. " ..payload.message)
					elseif payload.cmd == 'JOINACCEPTED' then
						tick = payload.server_tick
						prepare_player(payload.colour)
						confirm_join()
					else
						dbg(event.data)
						dbg("unrecognised command:", payload.cmd)
					end
				elseif event and event.type == "connect" then
					dbg("connect msg received")
				elseif event and event.type == "disconnect" then
					disconnect("Server closed")
				end
			until not event
		end
	end
end

function game:draw()
	if user_alive then camera:attach() end
	love.graphics.setColor(255, 128, 128)
	love.graphics.circle( "fill", 0, 0, 150, 100 )
	reset_colour()
	for k, entity in pairs(world) do
		if entity.entity_type == "PLAYER" then
			local img = get_entity_image(player)
			if player.orientation == "LEFT" then
				love.graphics.draw(img, entity.x, entity.y, 0, -1, 1)
			elseif player.orientation == "RIGHT" then
				love.graphics.draw(img, entity.x, entity.y, 0)
			end

		elseif entity.entity_type == "ENEMY" then
			local enemy = world[k]
			love.graphics.draw(get_entity_image(enemy), enemy.x, enemy.y)
		end
	end

	if settings.debug then
		local camX, camY = camera:position()
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.circle('fill', camX, camY, 2, 16)
		love.graphics.rectangle('line', camX - love.graphics.getWidth()*0.05, camY - love.graphics.getHeight()*0.035, 0.1*love.graphics.getWidth(), 0.07*love.graphics.getHeight())
		reset_colour()
		set_font_size(12)
		love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), camera:worldCoords(0,0))
		reset_font()
	end

	if not connected then
		love.graphics.print("Awaiting connection to server.", camera:worldCoords(0, 0))
	end
	if user_alive then camera:detach() end
end
