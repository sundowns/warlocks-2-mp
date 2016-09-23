world = {}

function add_entity(name, entity_type, ent)
	if entity_type == "PLAYER" then
		if name == settings.username then
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
			x = enemy.x,
 			y = enemy.y,
			x_vel = enemy.x_vel,
			y_vel = enemy.y_vel,
 			orientation = "RIGHT",
 			state ="STAND",
 			states = {},
 			height = nil,
			width = nil
	}

	enemy.states["STAND"] = {
		frames={},
		currentFrame = 1
	}

	enemy.states["STAND"].frames = {
		love.graphics.newImage("assets/player/".. enemy.colour .."/stand.png"),
	}

	enemy.height = enemy.states["STAND"].frames[1]:getHeight()
	enemy.width = enemy.states["STAND"].frames[1]:getWidth()

	world[name] = enemy
end

function get_entity_image(ent)
	return ent.states[ent.state].frames[ent.states[ent.state].currentFrame]
end

function update_entities(dt)
	for name, entity in pairs(world) do
		if entity.entity_type == "ENEMY" then
				update_entity_movement(dt, entity, constants.PLAYER_FRICTION)
		end
		update_sprite_instance(entity.instance, dt)
	end
end

function update_entity_movement(dt, entity, friction, isPlayer)
	entity.x = round_to_nth_decimal((entity.x + (entity.x_vel * dt)),2)
	entity.y = round_to_nth_decimal((entity.y + (entity.y_vel * dt)),2)

	--Movement velocity - movement friction
	if entity.x_vel > 1 then
		entity.orientation = "RIGHT"
		entity.x_vel = math.max(0, entity.x_vel - (friction * dt))
	elseif entity.x_vel < -1 then
		entity.orientation = "LEFT"
		entity.x_vel = math.min(0, entity.x_vel + (friction * dt))
	end

	if entity.y_vel > 1 then
		entity.y_vel = math.max(0, entity.y_vel - (friction * dt))
	elseif entity.y_vel < -1 then
		entity.y_vel = math.min(0, entity.y_vel + (friction * dt))
	end

	if entity.x_vel < 1 and entity.x_vel > -1 and entity.y_vel < 1 and entity.y_vel > -1 then
		entity.x_vel = 0
		entity.y_vel = 0
		if isPlayer then
			update_player_state("STAND")
		end
	end
end
