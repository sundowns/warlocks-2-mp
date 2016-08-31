world = {}
enemies = {}

function add_entity(name, entity_type, ent)
	if entity_type == "PLAYER" then
		world[name] = ent
	elseif entity_type == "ENEMY" then
		add_enemy(name, ent)
	end
	--maybe initialise x and y to 0 if they dont exist?
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

	player.height = player.states["STAND"].animation[1].left:getHeight()
	player.width = player.states["STAND"].animation[1].left:getWidth()

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