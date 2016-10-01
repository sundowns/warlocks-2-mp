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
			sprite_instance = {},
 			height = nil,
			width = nil
	}

	enemy.sprite_instance = get_sprite_instance("assets/sprites/player-" .. enemy.colour ..".lua")

	-- enemy.height = enemy.states["STAND"].frames[1]:getHeight()
	-- enemy.width = enemy.states["STAND"].frames[1]:getWidth()
	enemy.height = 20
	enemy.width = 20

	world[name] = enemy
end

function server_entity_update(entity, update)
	assert(update.x and update.y and update.entity_type and update.x_vel and update.y_vel and update.state)
	x, y, x_vel, y_vel = tonumber(payload.x), tonumber(payload.y), tonumber(payload.x_vel), tonumber(payload.y_vel)

	local ent = world[entity]
	if not ent then return nil end
	ent = update_entity_state(ent, update.state) --COMMENTED UNTIL WE GET SERVER DATA CORRECTION
	ent = update_entity_position(ent, x, y, x_vel, y_vel)
	world[entity] = ent
end

function server_entity_create(entity)
	print_table(entity)
	assert(entity.x, "Invalid x coordinate value for entity creation")
	assert(entity.y, "Invalid y coordinate value for entity creation")
	assert(entity.entity_type, "Invalid entity_type value for entity creation")
	--assert(entity.state, "Invalid state value for entity creation")
	x, y, x_vel, y_vel = tonumber(entity.x), tonumber(entity.y), tonumber(entity.x_vel), tonumber(entity.y_vel)
	add_entity(entity.alias, entity.entity_type, {name = entity.alias, colour = entity.colour or nil, x=x, y=y, x_vel=x_vel or 0, y_vel=y_vel or 0, state=entity.state})
end

function update_entities(dt)
	for name, entity in pairs(world) do
		if entity.entity_type == "ENEMY" then
				update_entity_movement(dt, entity, constants.PLAYER_FRICTION)
		end
		update_sprite_instance(entity.sprite_instance, dt)
	end
end

function update_entity_position(entity, x, y, x_vel, y_vel)
	entity.x = round_to_nth_decimal(x, 2)
	entity.y = round_to_nth_decimal(y, 2)
	entity.x_vel = round_to_nth_decimal(x_vel, 2)
	entity.y_vel = round_to_nth_decimal(y_vel, 2)
	return entity
end

function update_entity_state(entity, state)
	if entity.state ~= state then
		 entity.state = state
		 entity.sprite_instance.curr_anim = state
		 entity.sprite_instance.curr_frame = 1
	 end
	 --ent.height = ent.sprite_instance.sprite.animations[state][1]:getHeight()
	 --ent.width = ent.sprite_instance.sprite.animations[state][1]:getWidth()
	 return entity
end

function update_entity_movement(dt, entity, friction, isPlayer)
	entity.x = round_to_nth_decimal((entity.x + (entity.x_vel * dt)),2)
	entity.y = round_to_nth_decimal((entity.y + (entity.y_vel * dt)),2)

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
		if isPlayer and entity.state ~= "TURN" then
			update_player_state("STAND")
		end
	end
end

function prepare_camera()
	camera = Camera(0, 0)
	camera:zoom(2)
end

function update_camera()
	local camX, camY = camera:position()
	local newX, newY = camX, camY
	if (player.x > camX + love.graphics.getWidth()*0.05) then
		newX = player.x - love.graphics.getWidth()*0.05
	end
	if (player.x < camX - love.graphics.getWidth()*0.05) then
		newX = player.x + love.graphics.getWidth()*0.05
	end
	if (player.y > camY + love.graphics.getHeight()*0.035) then
		newY = player.y - love.graphics.getHeight()*0.035
	end
	if (player.y < camY - love.graphics.getHeight()*0.035) then
		newY = player.y + love.graphics.getHeight()*0.035
	end

	--camera:lookAt(newX, newY)
	camera:lockPosition(newX, newY, camera.smooth.damped(3))
end
