player_state_buffer = {}
player_buffer_size = 0
 --ticks in the past kept

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
	  	max_movement_velocity = 130,
	  	base_acceleration = 320,
			acceleration = 320,
			dash = {
				acceleration = 180,
				duration = 0.3,
				timer = 0.3,
				cancellable_after = 0.1 --after timer is 0.7, so after 0.3seconds
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

function process_input(dt) -- YOU NEED TO HAVE A SYSTEM FOR POLLING INPUTS, SO MOVEMENT IS CONSISTENT ACROSS ALL PLATFORMS
	if player.state == "STAND" or player.state == "RUN" or player.state == "DASH" then --or player.state == "TURN"
		local dash_multiplier = 1
		if player.state == "DASH" then dash_multiplier = 1.5 end
		if love.keyboard.isDown(settings.controls['RIGHT'])  then
			player.x_vel = math.min(player.x_vel + (player.acceleration*dash_multiplier)*dt, player.max_movement_velocity)
			if (player.x_vel > -1*player.dash.acceleration and player.state == "STAND") or (player.state == "DASH" and player.orientation == "LEFT" and player.dash.timer < player.dash.cancellable_after) then
				begin_dash("RIGHT")
			end
		end
		if love.keyboard.isDown(settings.controls["LEFT"]) then
			player.x_vel = math.max(player.x_vel - (player.acceleration*dash_multiplier)*dt, -1*player.max_movement_velocity)
			if (player.x_vel < player.dash.acceleration and player.state == "STAND") or (player.state == "DASH" and player.orientation == "RIGHT" and player.dash.timer < player.dash.cancellable_after) then
				begin_dash("LEFT")
			end
		end
		if love.keyboard.isDown(settings.controls["UP"]) then
			player.y_vel = math.max(player.y_vel - (player.acceleration*dash_multiplier)*dt , -1*player.max_movement_velocity)
			if player.y_vel < player.dash.acceleration and player.state == "STAND" then
				begin_dash("UP")
			end
		end
		if love.keyboard.isDown(settings.controls["DOWN"]) then
			player.y_vel = math.min(player.y_vel + (player.acceleration*dash_multiplier)*dt, player.max_movement_velocity)
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
end

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
	update_entity_state(player, state)
end

function update_player_movement(dt)
	local friction = constants['PLAYER_FRICTION']
	if (not love.keyboard.isDown(settings.controls["UP"])
	and not love.keyboard.isDown(settings.controls["DOWN"])
	and not love.keyboard.isDown(settings.controls["LEFT"])
	and not love.keyboard.isDown(settings.controls["RIGHT"])) then
		friction = friction*3
	end
	update_entity_movement(dt, player, friction, true)
end

function get_input_snapshot()
	return {
		up = love.keyboard.isDown((settings.controls["UP"])),
		right = love.keyboard.isDown((settings.controls["RIGHT"])),
		left = love.keyboard.isDown((settings.controls["LEFT"])),
		down = love.keyboard.isDown((settings.controls["DOWN"])),
	}
end

function create_player_state_snapshot(x, y, x_vel, y_vel, state)
	return {
		x = x,
		y = y,
		x_vel = x_vel,
		y_vel = y_vel,
		state = state
	}
end

function get_player_state_snapshot()
	return {
		x = player.x,
		y = player.y,
		x_vel = player.x_vel,
		y_vel = player.y_vel,
		state = player.state
	}
end

function retroactive_player_state_calc(update)
	--insert new player state into buffer
	local updated_state = create_player_state_snapshot(update.x, update.y, update.x_vel, update.y_vel, update.state)
	player_state_buffer[update.server_tick].player = updated_state

	--delete all states older than update
	local older = 0
	local newer = 0
	for k in pairs(player_state_buffer) do
		if k < update.server_tick then
			print("k: " .. k .. " svrTick: " ..update.server_tick)
    	player_state_buffer[k] = nil
			player_buffer_size = player_buffer_size - 1
			older = older + 1
		else newer = newer + 1
		end
	end
	print("older: " .. older .. " newer: " .. newer .. " t: " .. update.server_tick)

	local index = update.server_tick
	local result_state = {}
	for index=update.server_tick, tick do
		--result_state = calc_new_player_state(old_state, input, dt) --(dt = 1 tick)
		--update that state in the player_state_buffer
		--player_state_buffer[index] = result_state
		--calculate subsequent states
	end

	--update player with result state
end

function calc_new_player_state(old_state, input, dt)
	--Apply input & dt to old state to calc new state.
	--Return new state
end
