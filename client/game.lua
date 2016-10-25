game = {} -- the game state

function game:init()
	require("world")
	require("player")
	require("spritemanager")
	require("stagemanager")
	net_initialise()
	load_stage("arena1.lua")
	tick = 0
	tick_timer = 0
end

function game:enter(previous)
  love.graphics.setBackgroundColor(0,0,0)
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

		if connected and user_alive then
			local player_state = {player = get_player_state_snapshot(), input = get_input_snapshot(), tick = tick}
	   	player_state_buffer[tick] = player_state
			player_buffer_size = player_buffer_size + 1
	   	if player_buffer_size > constants.PLAYER_BUFFER_LENGTH then
				--print("buffer size ("..player_buffer_size..") is greater than " .. constants.PLAYER_BUFFER_LENGTH .. ". Removing oldest item @ " .. tick-constants.PLAYER_BUFFER_LENGTH .. " (curr_tick: " .. tick..")")
	   		player_state_buffer[tick-constants.PLAYER_BUFFER_LENGTH] = nil
				player_buffer_size = player_buffer_size - 1
	   	end
	 	end

		if tick%constants.NET_UPDATE_RATE == 0 then
			if user_alive then
				send_player_update(player, settings.username)
			end

			repeat
				event = listen()
				if event and event.type == "receive" then
					payload = json.decode(event.data)
					if payload.cmd == "ENTITYUPDATE" then
						assert(payload.alias)
						assert(payload.server_tick)
						sync_client(payload.server_tick)
						--dbg("received a msg from server at server_tick: " .. payload.server_tick.. " curr_client_tick: " .. tick)
						if world[payload.alias] == nil then
							server_entity_create(payload)
						else
							if payload.alias ~= player.name then --were not updating ourself???
								server_entity_update(payload.alias, payload)
							else
								server_player_update(payload)
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
	draw_stage()
	reset_colour()
	for k, entity in pairs(world) do
			if entity.orientation == "LEFT" then
				draw_instance(entity.sprite_instance, entity.x+entity.width/2, entity.y-entity.height/2, true)
			elseif entity.orientation == "RIGHT" then
				draw_instance(entity.sprite_instance, entity.x-entity.width/2, entity.y-entity.height/2)
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
		if user_alive then
			love.graphics.setColor(0, 255, 255, 255)
			love.graphics.circle('fill', player.x, player.y, 2, 16)
			reset_colour()
		end
	end

	if not connected then
		love.graphics.print("Awaiting connection to server.", camera:worldCoords(0, 0))
	end
	if user_alive then camera:detach() end
end
