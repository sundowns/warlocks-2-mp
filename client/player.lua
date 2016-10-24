player_state_buffer = {}
player_buffer_size = 0
player_buffer_length = 256 --ticks in the past kept 

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
	--dbg("changing from " .. player.state .. " to " .. state)
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
