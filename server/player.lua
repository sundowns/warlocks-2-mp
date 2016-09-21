function construct_player(name, x, y)
	local player = {
			x = x,
			y = y,
	  	name = name,
	  	entity_type = "PLAYER", 
	  	state = "STAND",
	  	x_vel = 0,
	  	y_vel = 0,
	  	max_movement_velocity = 140,
	  	acceleration = 35,
	  	movement_friction = 200,
	  	height = nil,
	  	width = nil,
	  	colour = colour
  	}
  	return player
end
