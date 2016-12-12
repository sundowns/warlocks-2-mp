game = {} -- the game state

function game:init()
	require("world")
	require("player")
	require("spritemanager")
	require("stagemanager")
	net_initialise()
    -- wait and request this from server if its not loaded
	load_stage("arena2.lua")
	tick = 0
	tick_timer = 0
end

function game:enter(previous)
  love.graphics.setBackgroundColor(0,0,0)
  if stage ~= nil then
      prepare_camera(stage.width*stage.tilewidth/2, stage.height*stage.tilewidth/2, 1.5)
  else
      prepare_camera(0,0,0)
  end
  update_camera_boundaries()
end

function game:update(dt)
	tick_timer = tick_timer + dt
	update_connection(dt)

	if user_alive then
		local input = get_input_snapshot()
		player = process_movement_input(player, input, dt) ----------\ KEEP THESE TWO ONE AFTER THE OTHER
        -- PROCESS SPELLS ETC!!

		update_player_movement(player, input, dt, false)--/ KEEP THESE TWO ONE AFTER THE OTHER
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
	            player_state_buffer[tick-constants.PLAYER_BUFFER_LENGTH] = nil
				player_buffer_size = player_buffer_size - 1
   	        end
	 	end

		if tick%constants.NET_PARAMS.NET_UPDATE_RATE == 0 then
			if user_alive then
				send_player_update(player, settings.username)
			end

			repeat
				event = listen()
				if event and event.type == "receive" then
					payload = binser.deserialize(event.data)
					setmetatable(payload, packet_meta)
					if payload.cmd == "ENTITYUPDATE" then
						assert(payload.alias)
						assert(payload.server_tick)
						sync_client(payload.server_tick)
						if world[payload.alias] == nil and world['projectiles'][payload.alias] == nil then
							server_entity_create(payload)
						else
							if payload.alias ~= player.name then
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
						player_colour = payload.colour
						confirm_join()
					elseif payload.cmd == 'SPAWN' then
                        local ok, update = verify_spawn_packet(payload)
                        if ok then
                            prepare_player(update)
                        end
                    elseif payload.cmd == 'PLAYERCORRECTION' then
                        local ok, update = verify_player_correction_packet(payload)
                        if ok then
                            apply_retroactive_updates(update)
                        end
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

    --draw players
	for k, entity in pairs(world) do
        if entity.entity_type == "PLAYER" or entity.entity_type == "ENEMY" then
            local ent_x, ent_y = entity:centre()
            if entity.orientation == "LEFT" then
				draw_instance(entity.sprite_instance, ent_x, ent_y, true) --+entity.width/2 -entity.height/2
			elseif entity.orientation == "RIGHT" then
				draw_instance(entity.sprite_instance, ent_x, ent_y) ---+entity.width/2 -entity.height/2
			end
        end
	end

    for k, projectile in pairs(world['projectiles']) do
        -- get maths from warlocks mk 1 for centre-point of front-facing edge of projectiles
        draw_instance(projectile.sprite_instance, projectile.x, projectile.y)
    end

	if settings.debug then
		local camX, camY = camera:position()
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.circle('fill', camX, camY, 2, 16)
		love.graphics.rectangle('line', camX - love.graphics.getWidth()*cameraBoxWidth, camY - love.graphics.getHeight()*cameraBoxHeight, 2*cameraBoxWidth*love.graphics.getWidth(), 2*cameraBoxHeight*love.graphics.getHeight())
		reset_colour()
		set_font(12, 'debug')
		love.graphics.print("fps: "..tostring(love.timer.getFPS( )), camera:worldCoords(3,-15))
		if user_alive then
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.circle('fill', player.x, player.y, 2, 16)
			reset_colour()
		end
		display_net_info()
		love.graphics.print("tick: "..tostring(tick), camera:worldCoords(3,15))

        for i, projectile in ipairs(world["projectiles"]) do
            love.graphics.setColor(0, 255, 0, 255)
            love.graphics.circle('fill', projectile.x, projectile.y, 1, 16)
            reset_colour()
        end
		local stats = love.graphics.getStats()
		love.graphics.print("texture memory (MB): ".. stats.texturememory / 1024 / 1024, camera:worldCoords(3, 80))
		love.graphics.print("drawcalls: ".. stats.drawcalls, camera:worldCoords(3, 100))
		love.graphics.print("canvasswitches: ".. stats.canvasswitches , camera:worldCoords(3, 120))
		love.graphics.print("images loaded: ".. stats.images, camera:worldCoords(3, 140))
		love.graphics.print("canvases loaded: ".. stats.canvases, camera:worldCoords(3, 160))
		love.graphics.print("fonts loaded: ".. stats.fonts, camera:worldCoords(3, 180))
		reset_font()
	end

	if not connected then
		love.graphics.print("Awaiting connection to server.", camera:worldCoords(0, 0))
	end
	if user_alive then camera:detach() end
end

function game:keyreleased(key, code)
    if key == settings.controls['SPELL1'] then
        if not user_alive then return end
        if not player.spellbook['SPELL1'] then end

        local x, y = love.mouse.getPosition()
        x,y = camera:worldCoords(x,y)
        local player_x, player_y = player:centre()
        send_action_packet("CASTSPELL", {at_X=x, at_Y=y, player_x = player.x, player_y = player.y, spell_type=player.spellbook['SPELL1']})
    end
end
