function spawn_player(name, x, y, colour)
	local new_player = {
		x = x,
		y = y,
	  	name = name,
	  	entity_type = "PLAYER",
	  	state = "STAND",
		orientation = "RIGHT",
	  	x_vel = 0,
	  	y_vel = 0,
	  	max_movement_velocity = 130,
	  	movement_friction = 200,
		base_acceleration = 320,
		acceleration = 320,
		dash = {
			acceleration = 180,
			duration = "0.3", --for some reason bitser hates decimals in tables?
			timer = "0.3",
			cancellable_after = "0.1" --after timer is 0.7, so after 0.3seconds
		},
	  	height = 20,
	  	width = 20,
	  	colour = colour
  	}
	world["players"][payload.alias] = new_player
	return new_player
end


function player_cast_fireball(alias, atX, atY)
end
