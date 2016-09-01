player_state_buffer = {}

function prepare_player(name, colour)
	player = {
			x = 0,
			y = 0,
	  	name = name,
	  	entity_type = "PLAYER", 
	  	state ="STAND",
	  	anim_states = {},
	  	orientation = "RIGHT",
	  	x_vel = 0,
	  	y_vel = 0,
	  	max_movement_velocity = 140,
	  	acceleration = 35,
	  	movement_friction = 200,
	  	controls = {},
	  	height = nil,
	  	width = nil,
	  	colour = colour
  	}	

	player.anim_states["STAND"] = {
		animation={},
		currentFrame = 1
	}

	player.anim_states["STAND"].animation[1] = {
		right = love.graphics.newImage("assets/player/" ..player.colour.."/stand-right.png"),
		left = love.graphics.newImage("assets/player/" ..player.colour.."/stand-left.png")
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

function process_input() 
	if player.state == "STAND" or player.state == "RUN" then 
		if love.keyboard.isDown(player.controls['RIGHT'])  then
			player.x_vel = math.min(player.x_vel + player.acceleration, player.max_movement_velocity)
		end 
		if love.keyboard.isDown(player.controls['LEFT']) then
			player.x_vel = math.max(player.x_vel - player.acceleration, -1*player.max_movement_velocity) 
		end
		if love.keyboard.isDown(player.controls['UP']) then
			player.y_vel = math.max(player.y_vel - player.acceleration, -1*player.max_movement_velocity)
		end
		if love.keyboard.isDown(player.controls['DOWN']) then
			player.y_vel = math.min(player.y_vel + player.acceleration, player.max_movement_velocity)
		end
	end
end

function update_player_state(state)
	player.anim_states[player.state].currentFrame = 1
	player.state = state
	player.height = player.anim_states[state].animation[1].left:getHeight()
	player.width = player.anim_states[state].animation[1].left:getWidth()
end

function calculate_player_movement(dt)
	player.x = round_to_nth_decimal((player.x + (player.x_vel * dt)),2)
	player.y = round_to_nth_decimal((player.y + (player.y_vel * dt)),2)
	
	--Movement velocity - movement friction	
	if player.x_vel > 1 then 
		player.orientation = "RIGHT"
		player.x_vel = math.max(0, player.x_vel - (player.movement_friction * dt))
	elseif player.x_vel < -1 then
		player.orientation = "LEFT"
		player.x_vel = math.min(0, player.x_vel + (player.movement_friction * dt)) 
	end

	if player.y_vel > 1 then 
		player.y_vel = math.max(0, player.y_vel - (player.movement_friction * dt)) 
	elseif player.y_vel < -1 then
		player.y_vel = math.min(0, player.y_vel + (player.movement_friction * dt)) 
	end

	if player.x_vel < 1 and player.x_vel > -1 and player.y_vel < 1 and player.y_vel > -1 then
		player.x_vel = 0
		player.y_vel = 0
	end

	--Impact velocity - impact friction
	-- if player.x_impact_velocity > 0 then 	
	-- 	player.x_impact_velocity = math.max(0, player.x_impact_velocity - (player.impact_friction * dt))
	-- elseif player.x_impact_velocity < 0 then
	-- 	player.x_impact_velocity = math.min(0, player.x_impact_velocity + (player.impact_friction * dt)) 
	-- end

	-- if player.y_impact_velocity > 0 then 
	-- 	player.y_impact_velocity = math.max(0, player.y_impact_velocity - (player.impact_friction * dt)) 
	-- elseif player.y_impact_velocity < 0 then
	-- 	player.y_impact_velocity = math.min(0, player.y_impact_velocity + (player.impact_friction * dt)) 
	-- end

	
end