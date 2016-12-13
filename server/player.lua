function spawn_player(name, x, y, colour)
	local new_player = {
		x = x,
		y = y,
	  	name = name,
	  	entity_type = "PLAYER",
	  	state = "STAND",
		orientation = "RIGHT",
	  	--velocity = vector(0,0),
        x_vel = 0,
        y_vel = 0,
	  	max_movement_velocity = 130,
	  	movement_friction = 200,
		base_acceleration = 240,
		acceleration = 240,
		dash = {
			acceleration = 70,
			duration = "0.3", --for some reason bitser hates decimals in tables?
			timer = "0.3",
			cancellable_after = "0.1" --after timer is 0.7, so after 0.3seconds
		},
        width = 20,
	  	height = 22,
	  	colour = colour
  	}
	world["players"][payload.alias] = new_player
    world["players"][payload.alias].velocity = vector(0,0)
	return new_player
end


function player_cast_fireball(player_x, player_y, at_X, at_Y, alias)
    local vector = calc_vector_from_points(player_x, player_y, at_X, at_Y)
    spawn_projectile(player_x, player_y, vector, alias)
end

function calc_vector_from_points(fromX, fromY, toX, toY)
    return vector(toX-fromX, toY-fromY)
end
