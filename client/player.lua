player_state_buffer = {}

function prepare_player(colour)
	player = {
			x = 0,
			y = 0,
	  	name = settings.username,
	  	entity_type = "PLAYER",
	  	state ="STAND",
	  	orientation = "RIGHT",
	  	x_vel = 0,
	  	y_vel = 0,
	  	max_movement_velocity = 140,
	  	base_acceleration = 250,
			acceleration = 250,
			dash = {
				acceleration = 100,
				duration = 1,
				timer = 1,
				cancellable_after = 0.7 --after timer is 0.7, so after 0.3seconds
			},
			turn = {
				duration = 0.275,
				timer = 0.275
			},
			sprite_instance = {},
	  	controls = {},
	  	height = nil,
	  	width = nil,
	  	colour = colour
  	}

	player.sprite_instance = get_sprite_instance("assets/sprites/player-" .. colour ..".lua")

	--FIGURE OUT HOW TO GET VIA SPIRTE SHEET
	--player.height = player.sprite_instance.sprite.animations["STAND"][1]:getHeight()
	--player.width = player.sprite_instance.sprite.animations["STAND"][1]:getWidth()
	player.height = 20
	player.width = 20

	add_entity(player.name, "PLAYER", player)
	user_alive = true
end

function process_input(dt)
	if player.state == "STAND" or player.state == "RUN" or player.state == "DASH" then --or player.state == "TURN"
		local bonus = 0
		if player.state == "DASH" then bonus = 50 end
		if love.keyboard.isDown(settings.controls['RIGHT'])  then
			player.x_vel = math.min(player.x_vel + (player.acceleration+bonus)*dt, player.max_movement_velocity)
			if (player.x_vel > -1*player.dash.acceleration and player.state == "STAND") or (player.state == "DASH" and player.orientation == "LEFT" and player.dash.timer < player.dash.cancellable_after) then
				begin_dash("RIGHT")
			end
			-- if player.x_vel < 0 and player.state == "RUN" then -- we were going left, lets turn
			-- 	begin_turn("RIGHT")
			-- end

		end
		if love.keyboard.isDown(settings.controls["LEFT"]) then
			player.x_vel = math.max(player.x_vel - (player.acceleration-bonus)*dt, -1*player.max_movement_velocity)
			if (player.x_vel < player.dash.acceleration and player.state == "STAND") or (player.state == "DASH" and player.orientation == "RIGHT" and player.dash.timer < player.dash.cancellable_after) then
				begin_dash("LEFT")
			end
			-- if player.x_vel > 0 and player.state == "RUN" then -- we were going right, lets turn
			-- 	begin_turn("LEFT")
			-- end
			if player.state == "DASH" and player.orientation == "RIGHT" then
				begin_dash("LEFT")
			end
		end
		if love.keyboard.isDown(settings.controls["UP"]) then
			player.y_vel = math.max(player.y_vel - (player.acceleration-bonus)*dt , -1*player.max_movement_velocity)
			if player.y_vel < player.dash.acceleration and player.state == "STAND" then
				begin_dash("UP")
			end
		end
		if love.keyboard.isDown(settings.controls["DOWN"]) then
			player.y_vel = math.min(player.y_vel + (player.acceleration+bonus)*dt, player.max_movement_velocity)
			if player.y_vel > -1*player.dash.acceleration and player.state == "STAND" then
				begin_dash("DOWN")
			end
		end
	end
end

function cooldowns(dt)
	if player.state == "DASH" then
		player.dash.timer = player.dash.timer - dt
	end

	if player.dash.timer < 0 then
		end_dash()
	end

	-- if player.state == "TURN" then
	-- 	player.turn.timer = player.turn.timer - dt
	-- end
	--
	-- dbg("turn timer: " .. player.turn.timer .. " duration: " .. player.turn.duration)
	-- if player.turn.timer < 0 then
	-- 	end_turn()
	-- end
end

-- function begin_turn(direction)
-- 	update_player_state("TURN")
-- 	player.acceleration =	round_to_nth_decimal(player.acceleration*0.3, 2)
-- end
--
-- function end_turn()
-- 	player.turn.timer = player.turn.duration
-- 	print("WE ENDING TURN")
-- 	update_player_state("STAND")
-- 	player.acceleration = round_to_nth_decimal(player.acceleration*(1/0.3), 2)
-- end

function begin_dash(direction)
	update_player_state("DASH")
	player.dash.timer = player.dash.duration
	player.dash.direction = direction
	player.acceleration = player.acceleration + player.dash.acceleration
end

function end_dash()
	player.dash.timer = player.dash.duration
	update_player_state("RUN")
	player.acceleration = player.acceleration - player.dash.acceleration
end

function update_player_state(state)
	--dbg("changing from " .. player.state .. " to " .. state)
	update_entity_state(player, state)
end

function update_player_movement(dt)
	update_entity_movement(dt, player, constants['PLAYER_FRICTION'], true)
end
