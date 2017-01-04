player_state_buffer = {}
player_buffer_size = 0
player_colour = nil
player = {}
 --ticks in the past kept

function prepare_player(player_data)
	player = player_data
	player.dash.duration = tonumber(player.dash.duration)
	player.dash.timer = tonumber(player.dash.timer)
	player.dash.cancellable_after = tonumber(player.dash.cancellable_after)

	player.sprite_instance = get_sprite_instance("assets/sprites/player-" .. player.colour ..".lua")

    player.spellbook = {}
    player.spellbook['SPELL1'] = "FIREBALL"

    function player:centre() -- PUT THESE INTO AN ENTITY SUPERCLASS
        if self.orientation == "LEFT" then
            return self.x + self.width/2, self.y - self.height/2
        elseif self.orientation == "RIGHT" then
            return self.x - self.width/2, self.y - self.height/2
        end
    end
    player.velocity = vector(player_data.x_vel, player_data.y_vel)
	add_entity(player.name, player.entity_type, player)
	user_alive = true
end

function process_movement_input(player_obj, inputs, dt)
    -- TODO: POLLING SYSTEM
    -- PLAN:
    -- have an input polling function seperate of normal game tick (possible????????) that puts inputs in a buffer as they come
    -- then on every tick, empty the buffer and calculate the average direction vector of the inputs.
    -- Normalise this (necessary?) and use as the input for that tick (and thus one to save in buffer)
    local resultant_input = vector(0,0)
	if player_obj.state == "STAND" or player_obj.state == "RUN" or player_obj.state == "DASH" then --or player.state == "TURN"
		local dash_multiplier = 1
		if player_obj.state == "DASH" then dash_multiplier = 1.5 end
		if inputs.right and not inputs.left then
            resultant_input.x = 1
			if (player_obj.velocity.x > -1*player_obj.dash.acceleration and player_obj.state == "STAND") then --or (player_obj.state == "DASH" and player_obj.orientation == "LEFT" and player.dash.timer < player.dash.cancellable_after)
				begin_dash("RIGHT")
			end
		end
		if inputs.left and not inputs.right then
            resultant_input.x = -1
			if (player_obj.velocity.x < player_obj.dash.acceleration and player_obj.state == "STAND") then --or (player_obj.state == "DASH" and player_obj.orientation == "RIGHT" and player.dash.timer < player.dash.cancellable_after)
				begin_dash("LEFT")
			end
		end
		if inputs.up and not inputs.down then
            resultant_input.y = -1
			if player_obj.velocity.y < player_obj.dash.acceleration and player_obj.state == "STAND" then
				begin_dash("UP")
			end
		end
		if inputs.down and not inputs.up then
            resultant_input.y = 1
			if player_obj.velocity.y > -1*player_obj.dash.acceleration and player_obj.state == "STAND" then
				begin_dash("DOWN")
			end
		end

        resultant_input:normalizeInplace()
        player_obj.velocity = player_obj.velocity + resultant_input * player_obj.acceleration * dash_multiplier * dt

        if player_obj.velocity:len() > player_obj.max_movement_velocity then
            player_obj.velocity = player_obj.velocity:normalized() * player_obj.max_movement_velocity
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
		friction = friction*2
	end

    if inputs.left and not inputs.right then player_obj.orientation = "LEFT" end
    if inputs.right and not inputs.left then player_obj.orientation = "RIGHT" end

	player_obj = update_entity_movement(dt, player_obj, friction, true, isRetroactive)
	return player_obj
end

function get_input_snapshot()
	return {
		up = love.keyboard.isDown((settings.controls["UP"])),
		right = love.keyboard.isDown((settings.controls["RIGHT"])),
		left = love.keyboard.isDown((settings.controls["LEFT"])),
		down = love.keyboard.isDown((settings.controls["DOWN"])),
        spell1 = love.keyboard.isDown((settings.controls["SPELL1"])),
        spell2 = love.keyboard.isDown((settings.controls["SPELL2"])),
        spell3 = love.keyboard.isDown((settings.controls["SPELL3"])),
        spell4 = love.keyboard.isDown((settings.controls["SPELL4"])),
        spell5 = love.keyboard.isDown((settings.controls["SPELL5"]))
	}
end

function create_player_state_snapshot(x, y, x_vel, y_vel, state, acceleration,
	orientation, dash, max_movement_velocity)
	return {
		x = x,
		y = y,
		x_vel = x_vel,
		y_vel = y_vel,
        velocity = vector(x_vel, y_vel),
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
        velocity = player.velocity,
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

	local index = update.server_tick
	--local result_state = {}
    local result_state = updated_state
	local updated = false
	for index=update.server_tick, tick-last_offset,2 do --Lets make sure we're not correcting events as they happen.
		local input = player_state_buffer[index].input
		result_state = calc_new_player_state(result_state, input, constants.TICKRATE*2) --(dt = 2 ticks)
		--update that state in the player_state_buffer
		local new_snapshot = {player=result_state,input=input,tick=index}
		player_state_buffer[index] = new_snapshot
		updated = true
	end

	--update player with result state
	if updated then
		apply_player_updates(result_state)
	end
end

function calc_new_player_state(previous_state, input, dt)
	--Apply input & dt to old state to calc new state.
	local resultant = process_movement_input(previous_state, input, dt)
	resultant = update_player_movement(resultant, input, dt, true)
	return resultant
end


function apply_player_updates(result)
	player.x = result.x
	player.y = result.y
	player.x_vel = result.x_vel
	player.y_vel = result.y_vel
	update_player_state(result.state)
end
