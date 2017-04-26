game = {} -- the game state
local scoreBoard = nil
hud = nil

testX1, testWidth, testY1, testHeight, testRotation = 0

function game:init()
    require("src.soundmanager")
	require("src.world")
    require("src.projectile")
    require("src.spell")
	require("src.player")
	require("src.spritemanager")
    require("src.scoremanager")
    require("src.hudmanager")
end

function game:enter(previous)
    tick_timer = 0
    love.graphics.setBackgroundColor(0,0,0)
    if stage ~= nil then
        prepare_camera(stage.width*stage.tilewidth/2, stage.height*stage.tilewidth/2, 2)
    else
        prepare_camera(0,0,0)
    end
    update_camera_boundaries()
    scoreBoard = ScoreManager()
    hud = HudManager()
end

function game:update(dt)
	tick_timer = tick_timer + dt
	update_connection(dt)
    Timer.update(dt)
    if tick_timer > constants.TICKRATE then -- THIS SHOULD BE USED FOR COMMUNCATION TO/FROM SERVER/KEEPING IN SYNC
		tick = tick + 1
		tick_timer = tick_timer - constants.TICKRATE

		if connected and user_alive then
            player.state_buffer:add(get_player_state_snapshot(), get_input_snapshot(), tick)
	 	end
		network_run()
	end

	if user_alive then
		local input = get_input_snapshot()
		process_movement_input(player, input, dt) ----------\ KEEP THESE TWO ONE AFTER THE OTHER
        -- PROCESS SPELLS ETC!!
		update_player_movement(player, input, dt, false)--/ KEEP THESE TWO ONE AFTER THE OTHER
		update_camera()
		player:updateCooldowns(dt)
        hud:update()
	end

    while #debug_log > 20 do
      table.remove(debug_log, 1)
    end

	update_entities(dt)
    process_collisions(dt)
end

function game:draw()
	if user_alive then camera:attach() end
	draw_stage()
	reset_colour()

    --draw players
	for k, entity in pairs(world) do
        if entity.entity_type == "PLAYER" or entity.entity_type == "ENEMY" then
            local cX, cY = entity:centre()
            if entity.orientation == "LEFT" then
				draw_instance(entity.sprite_instance, cX, cY, true)
			elseif entity.orientation == "RIGHT" then
				draw_instance(entity.sprite_instance, cX, cY)
			end
        end
	end

    for k, projectile in pairs(world['projectiles']) do
        projectile:draw()
        draw_instance(projectile.sprite_instance, projectile.position.x, projectile.position.y)
    end

    reset_colour()
    draw_foreground()

    for k, explosion in pairs(world['explosions']) do
        explosion:draw()
    end

	if settings.debug then
		local camX, camY = camera:position()
		love.graphics.setColor(0, 0, 0, 100)
		love.graphics.circle('fill', camX, camY, 2, 16)
		love.graphics.rectangle('line', camX - love.graphics.getWidth()*cameraBoxWidth, camY - love.graphics.getHeight()*cameraBoxHeight, 2*cameraBoxWidth*love.graphics.getWidth(), 2*cameraBoxHeight*love.graphics.getHeight())
		reset_colour()
		set_font(12, 'debug')
		love.graphics.print("fps: "..tostring(love.timer.getFPS( )), camera:worldCoords(3,-15))
		if user_alive then
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.circle('fill', player.position.x, player.position.y, 2, 16)
            player.hitbox:draw('line')
			reset_colour()
		end
		display_net_info()
		love.graphics.print("tick: "..tostring(tick), camera:worldCoords(3,15))

        for key, projectile in pairs(world["projectiles"]) do
            love.graphics.setColor(0, 255, 0, 255)
            love.graphics.circle('fill', projectile.position.x, projectile.position.y, 1, 16)
            projectile.hitbox:draw('line')
            reset_colour()
        end
        for i, ent in pairs(world) do
            if ent.entity_type == "ENEMY" then
                love.graphics.setColor(255, 10, 10, 255)
    			love.graphics.circle('fill', ent.position.x, ent.position.y, 2, 16)
                ent.hitbox:draw('line')
    			reset_colour()
            end
        end
        --server debug messages
        for i = 1,#debug_log do
            love.graphics.setColor(35,140,35, 255 - (i-1) * 8)
            love.graphics.print(debug_log[#debug_log - (i-1)], camera:worldCoords(3, 200+ i * 15))
        end

        --print last updated projectile hitbox vertices
        love.graphics.setColor(30,30,255, 200)
        love.graphics.polygon('line', testX1, testY1, testX2, testY2,testX3, testY3,testX4, testY4)

        if testEntX and testEntY then
            love.graphics.setColor(255, 0, 255, 200)
            love.graphics.circle('fill', testEntX, testEntY, 2, 16)
        end

        reset_font()
	end

    if settings.show_resource_info then
        reset_colour()
        set_font(12, 'debug')
        local stats = love.graphics.getStats()
		love.graphics.print("texture memory (MB): ".. stats.texturememory / 1024 / 1024, camera:worldCoords(3, 60))
		love.graphics.print("drawcalls: ".. stats.drawcalls, camera:worldCoords(3, 80))
		love.graphics.print("canvasswitches: ".. stats.canvasswitches , camera:worldCoords(3, 100))
		love.graphics.print("images loaded: ".. stats.images, camera:worldCoords(3, 120))
		love.graphics.print("canvases loaded: ".. stats.canvases, camera:worldCoords(3, 140))
		love.graphics.print("fonts loaded: ".. stats.fonts, camera:worldCoords(3, 160))
        reset_font()
    end

	if not connected then
		love.graphics.print("Awaiting connection to server.", camera:worldCoords(0, 0))
	end
	if user_alive then
        camera:detach()
        reset_colour()
        hud:draw()
    end

    if love.keyboard.isDown(settings.controls.SHOW_SCOREBOARD) then
        reset_colour()
        scoreBoard:draw()
    end
end

function game:keyreleased(key, code)
    if key == settings.controls['SPELL1'] then
        if not user_alive then return end
        player.spellbook:spellKeyPressed('SPELL1')
    elseif key == settings.controls['SPELL2'] then
        if not user_alive then return end
        player.spellbook:spellKeyPressed('SPELL2')
    elseif key == settings.controls['SPELL3'] then
        if not user_alive then return end
        player.spellbook:spellKeyPressed('SPELL3')
    elseif key == settings.controls['SPELL4'] then
        if not user_alive then return end
        player.spellbook:spellKeyPressed('SPELL4')
    elseif key == settings.controls['SPELL5'] then
        if not user_alive then return end
        player.spellbook:spellKeyPressed('SPELL5')
    elseif key == "f5" then
        print("[client_tick: " .. tick .. "][buffer_size ".. player.state_buffer:getCurrentSize() .. "][" .. "largest_tick " .. player.state_buffer.current_max_tick .. "]")
        player.state_buffer:printDump(true)
    end
end
