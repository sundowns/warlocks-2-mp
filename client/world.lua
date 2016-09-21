world = {}

function add_entity(name, entity_type, ent)
	if entity_type == "PLAYER" then
		if name == username then
			world[name] = ent
		else
			add_enemy(name, ent)
		end
	end
end

function remove_entity(name, entity_type)
	if world[name] then
		world[name] = nil
	end
end

function add_enemy(name, enemy)
	local enemy = {
			name = enemy.name,
			colour = enemy.colour,
			entity_type = "ENEMY",
			x = 0,
 			y = 0,
 			orientation = "RIGHT",
 			state ="STAND",
 			states = {},
 			height = nil,
  			width = nil
	}

	enemy.states["STAND"] = {
		animation={},
		currentFrame = 1
	}

	enemy.states["STAND"].animation[1] = {
		right = love.graphics.newImage("assets/player/".. enemy.colour .."/stand-right.png"),
		left = love.graphics.newImage("assets/player/".. enemy.colour .."/stand-left.png")
	}

	enemy.height = enemy.states["STAND"].animation[1].left:getHeight()
	enemy.width = enemy.states["STAND"].animation[1].left:getWidth()

	world[name] = enemy
end

function get_enemy_img(enemy)
	local img = nil
	if enemy.orientation == "RIGHT" then
		img = enemy.states[enemy.state].animation[enemy.states[enemy.state].currentFrame].right
	elseif enemy.orientation == "LEFT" then
		img = enemy.states[enemy.state].animation[enemy.states[enemy.state].currentFrame].left
	end
	return img
end
