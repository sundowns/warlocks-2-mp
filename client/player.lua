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

function process_input(player_obj, inputs, dt) -- YOU NEED TO HAVE A SYSTEM FOR POLLING INPUTS, SO MOVEMENT IS CONSISTENT ACROSS ALL PLATFORMS
	if player_obj.state == "STAND" or player_obj.state == "RUN" or player_obj.state == "DASH" then --or player.state == "TURN"
		local dash_multiplier = 1
		if player_obj.state == "DASH" then dash_multiplier = 1.5 end
		if inputs.right and not inputs.left then
			player_obj.x_vel = math.min(player_obj.x_vel + (player_obj.acceleration*dash_multiplier)*dt, player_obj.max_movement_velocity)
			if (player_obj.x_vel > -1*player_obj.dash.acceleration and player_obj.state == "STAND") or (player_obj.state == "DASH" and player_obj.orientation == "LEFT" and player.dash.timer < player.dash.cancellable_after) then
				begin_dash("RIGHT")
			end
		end
		if inputs.left and not inputs.right then
			player_obj.x_vel = math.max(player_obj.x_vel - (player_obj.acceleration*dash_multiplier)*dt, -1*player_obj.max_movement_velocity)
			if (player_obj.x_vel < player_obj.dash.acceleration and player_obj.state == "STAND") or (player_obj.state == "DASH" and player_obj.orientation == "RIGHT" and player.dash.timer < player.dash.cancellable_after) then
				begin_dash("LEFT")
			end
		end
		if inputs.up and not inputs.down then
			player_obj.y_vel = math.max(player_obj.y_vel - (player_obj.acceleration*dash_multiplier)*dt , -1*player_obj.max_movement_velocity)
			if player_obj.y_vel < player_obj.dash.acceleration and player_obj.state == "STAND" then
				begin_dash("UP")
			end
		end
		if inputs.down and not inputs.up then
			player_obj.y_vel = math.min(player_obj.y_vel + (player_obj.acceleration*dash_multiplier)*dt, player_obj.max_movement_velocity)
			if player_obj.y_vel > -1*player_obj.dash.acceleration and player_obj.state == "STAND" then
				begin_dash("DOWN")
			end
		end
	end

	return player_obj
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

function update_player_movement(player_obj, inputs, dt, isRetroactive)
	local friction = constants['PLAYER_FRICTION']
	if (not inputs.up and not inputs.down and
	not inputs.left and not inputs.right) then
		friction = friction*3
	end
	player_obj = update_entity_movement(dt, player_obj, friction, true, isRetroactive)
	return player_obj
end

function get_input_snapshot()
	return {
		up = love.keyboard.isDown((settings.controls["UP"])),
		right = love.keyboard.isDown((settings.controls["RIGHT"])),
		left = love.keyboard.isDown((settings.controls["LEFT"])),
		down = love.keyboard.isDown((settings.controls["DOWN"])),
	}
end

function create_player_state_snapshot(x, y, x_vel, y_vel, state, acceleration,
	orientation, dash, max_movement_velocity)
	return {
		x = x,
		y = y,
		x_vel = x_vel,
		y_vel = y_vel,
		state = state,
		acceleration = acceleration,
		orientation = orientation,
		dash = dash,
		max_movement_velocity = max_movement_velocity
	}
end

function get_player_state_snapshot()
	return {
		x = player.x,
		y = player.y,
		x_vel = player.x_vel,
		y_vel = player.y_vel,
		state = player.state,
		acceleration = player.acceleration,
		orientation = player.orientation,
		dash = player.dash,
		max_movement_velocity = player.max_movement_velocity
	}
end

function retroactive_player_state_calc(update)
	--insert new player state into buffer
	local old = player_state_buffer[update.server_tick]
	local updated_state = create_player_state_snapshot(update.x, update.y, update.x_vel, update.y_vel, update.state,
	 old.player.acceleration, old.player.orientation, old.player.dash, old.player.max_movement_velocity)
	old.player = updated_state
	player_state_buffer[update.server_tick] = old

	--delete all states older than update
	local older = 0
	local newer = 0
	for k in pairs(player_state_buffer) do
		if k < update.server_tick then
    	player_state_buffer[k] = nil
			player_buffer_size = player_buffer_size - 1
			older = older + 1
		else newer = newer + 1
		end
	end
	--print("older: " .. older .. " newer: " .. newer .. " t: " .. update.server_tick)

	local index = update.server_tick
	local result_state = {}
	local updated = false
	for index=update.server_tick, tick-last_offset,2 do --Lets make sure we're not correcting events as they happen.
		--print("index: ".. index .. " update svrTick: " .. update.server_tick .. " client tick: " .. tick)
		local input = player_state_buffer[index].input
		result_state = calc_new_player_state(updated_state, input, constants.TICKRATE*2) --(dt = 2 ticks)
		--update that state in the player_state_buffer
		local new_snapshot = {player=result_state,input=input,tick=index}
		player_state_buffer[index] = new_snapshot
		updated = true
	end

	--update player with result state
	if updated then
		apply_retroactive_updates(result_state)
	end
end

function calc_new_player_state(previous_state, input, dt)
	--Apply input & dt to old state to calc new state.
	local resultant = process_input(previous_state, input, dt)
	resultant = update_player_movement(resultant, input, dt, true)
	return resultant
end


function apply_retroactive_updates(result)
	player.x = result.x
	player.y = result.y
	player.x_vel = result.x_vel
	player.y_vel = result.y_vel
	player.acceleration = result.acceleration
	player.max_movement_velocity = result.max_movement_velocity
	player.dash = result.dash
	update_player_state(result.state)
end
