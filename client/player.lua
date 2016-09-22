player_state_buffer = {}

function prepare_player(colour)
	player = {
			x = 0,
			y = 0,
	  	name = settings.username,
	  	entity_type = "PLAYER",
	  	state ="STAND",
	  	anim_states = {},
	  	orientation = "RIGHT",
	  	x_vel = 0,
	  	y_vel = 0,
	  	max_movement_velocity = 140,
	  	base_acceleration = 250,
			acceleration = 250,
			dash = {
				acceleration = 600,
				duration = 0.4,
				timer = 0.2
			},
	  	controls = {},
	  	height = nil,
	  	width = nil,
	  	colour = colour
  	}

	player.anim_states["STAND"] = {
		animation={},
		currentFrame = 1
	}

	player.anim_states["DASH"] = {
		animation={},
		currentFrame = 1
	}

	player.anim_states["RUN"] = {
		animation={},
		currentFrame = 1
	}

	player.anim_states["STAND"].animation[1] = {
		right = love.graphics.newImage("assets/player/" ..player.colour.."/stand-right.png"),
		left = love.graphics.newImage("assets/player/" ..player.colour.."/stand-left.png")
	}
	player.anim_states["DASH"].animation[1] = {
		right = love.graphics.newImage("assets/player/" ..player.colour.."/dash-right.png"),
		left = love.graphics.newImage("assets/player/" ..player.colour.."/dash-left.png")
	}
	player.anim_states["RUN"].animation[1] = {
		right = love.graphics.newImage("assets/player/" ..player.colour.."/run-right.png"),
		left = love.graphics.newImage("assets/player/" ..player.colour.."/run-left.png")
	}

	player.controls['RIGHT'] = 'd'
	player.controls['LEFT'] = 'a'
	player.controls['UP'] = 'w'
	player.controls['DOWN'] = 's'
	player.controls['SPELL1'] = '1'
	player.controls['SPELL2'] = '2'
	player.controls['SPELL3'] = '3'
	player.controls['SPELL4'] = '4'
	player.controls['SPELL5'] = '5'

	player.height = player.anim_states["STAND"].animation[1].left:getHeight()
	player.width = player.anim_states["STAND"].animation[1].left:getWidth()

	add_entity(player.name, "PLAYER", player)

	user_alive = true
end

function get_player_img(player)
	local img = nil
	if player.orientation == "RIGHT" then
		img = player.anim_states[player.state].animation[player.anim_states[player.state].currentFrame].right
	elseif player.orientation == "LEFT" then
		img = player.anim_states[player.state].animation[player.anim_states[player.state].currentFrame].left
	end
	return img
end

function process_input(dt)
	if player.state == "STAND" or player.state == "RUN" or player.state == "DASH" then
		if love.keyboard.isDown(player.controls['RIGHT'])  then
			local bonus = 0
			if player.state == "DASH" then bonus = 50 end
			player.x_vel = math.min(player.x_vel + player.acceleration*dt + bonus*dt, player.max_movement_velocity)
			if player.x_vel > -1*player.dash.acceleration and player.state ~= "DASH" then
				begin_dash("RIGHT")
			end
		end
		if love.keyboard.isDown(player.controls["LEFT"]) then
			local bonus = 0
			if player.state == "DASH" then bonus = 100 end
			player.x_vel = math.max(player.x_vel - player.acceleration*dt - bonus*dt, -1*player.max_movement_velocity)
			if player.x_vel < player.dash.acceleration and player.state ~= "DASH" then
				begin_dash("LEFT")
			end
		end
		if love.keyboard.isDown(player.controls["UP"]) then
			local bonus = 0
			if player.state == "DASH" then bonus = 50 end
			player.y_vel = math.max(player.y_vel - player.acceleration*dt - bonus*dt, -1*player.max_movement_velocity)
			if player.y_vel < player.dash.acceleration and player.state ~= "DASH" then
				begin_dash("UP")
			end
		end
		if love.keyboard.isDown(player.controls["DOWN"]) then
			local bonus = 0
			if player.state == "DASH" then bonus = 50 end
			player.y_vel = math.min(player.y_vel + player.acceleration*dt + bonus*dt, player.max_movement_velocity)
			if player.y_vel < -40*player.dash.acceleration and player.state ~= "DASH" then
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
		player.dash.timer = player.dash.duration
		end_dash()
	end
end

function begin_dash(direction)
	print("BEGIN DASH")
	update_player_state("DASH")
	player.acceleration = player.acceleration + player.dash.acceleration
	player.dash.direction = direction
end

function end_dash()
	print("END DASH")
	update_player_state("RUN") -- MAKE THIS RUN WHEN U GOT ANIMATIONS
	player.acceleration = player.acceleration - player.dash.acceleration
end

function update_player_state(state)
	if player.state ~= state then player.state = state end
	--player.anim_states[player.state].currentFrame = 1
	-- player.height = player.anim_states[state].animation[1].left:getHeight()
	-- player.width = player.anim_states[state].animation[1].left:getWidth()
end

function update_player_movement(dt)
	update_entity_movement(dt, player, constants['PLAYER_FRICTION'], true)
end
