function prepare_player()
	player = {
		x = 0,
 		y = 0,
	  	name = "sundowns",
	  	state ="STAND",
	  	states = {},
	  	orientation = "RIGHT",
	  	x_vel = 0,
	  	y_vel = 0,
	  	max_movement_velocity = 140,
	  	acceleration = 35,
	  	controls = {}
  	}	

	player.states["STAND"] = {
		animation={},
		currentFrame = 1
	}

	player.states["STAND"].animation[1] = {
		right = love.graphics.newImage("assets/player/stand-right.png"),
		left = love.graphics.newImage("assets/player/stand-left.png")
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

	add_entity(player.name, "PLAYER", player)
end

function get_player_img(player)
	local img = nil
	if player.orientation == "RIGHT" then
		img = player.states[player.state].animation[player.states[player.state].currentFrame].right
	elseif player.orientation == "LEFT" then
		img = player.states[player.state].animation[player.states[player.state].currentFrame].left
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

	

	-- local x, y = 0, 0
	-- 	if love.keyboard.isDown('up') then		y=y-(20*worldTime) end
	-- 	if love.keyboard.isDown('down') then 	y=y+(20*worldTime) end
	-- 	if love.keyboard.isDown('left') then 	x=x-(20*worldTime) end
	-- 	if love.keyboard.isDown('right') then 	x=x+(20*worldTime) end
	-- 	local dg = string.format("%s %s %f %f", player.name, 'move', x, y)
	-- 	udp:send(dg)
end