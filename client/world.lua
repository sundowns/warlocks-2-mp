world = {}
world["projectiles"] = {}
local minCamX = 0
local minCamY = 0
local maxCamX = 2000
local maxCamY = 2000
cameraBoxHeight = 0.035
cameraBoxWidth = 0.05

-- world_meta = {}
-- --causes mem error coz loop
-- -- function world_meta.__index(table, key)
-- --     if type(key) == 'number' then
-- --         return table["projectiles"][key]
-- --     else
-- --         return table[key]
-- --     end
-- -- end
--
-- setmetatable(world, world_meta)

function add_entity(name, entity_type, ent)
	if entity_type == "PLAYER" then
		if name == settings.username then
			world[name] = ent
		else
			add_enemy(name, ent)
		end
    elseif entity_type == "PROJECTILE" then
        add_projectile(ent)
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

    print("wtf add_enemy")
	enemy.sprite_instance = get_sprite_instance("assets/sprites/player-" .. enemy.colour ..".lua")

	enemy.height = 20
	enemy.width = 20

	world[name] = enemy
end

function add_projectile(ent)
    local projectile = {
        name = ent.name,
        x = ent.x,
        y = ent.y,
        x_vel = ent.x_vel,
        y_vel = ent.y_vel,
        entity_type = "PROJECTILE",
        projectile_type = ent.projectile_type,
        sprite_instance = {},
        velocity = vector(ent.x_vel, ent.y_vel)
    }

    print("wtf add_projectile")
    projectile.sprite_instance = get_sprite_instance("assets/sprites/" .. projectile.projectile_type ..".lua")

    world['projectiles'][projectile.name] = projectile
end

function server_player_update(update)
	assert(update.x and update.y, "Undefined x or y coordinates for player update")
	assert(update.entity_type, "Undefined entity_type value for player update")
	assert(update.x_vel and update.y_vel, "Undefined x or y velocities for player update")
	update.x = tonumber(update.x)
	update.y = tonumber(update.y)
	update.x_vel = tonumber(update.x_vel)
	update.y_vel = tonumber(update.y_vel)
	local player_state = player_state_buffer[update.server_tick]
	if player_state then
		if not within_variance(player_state.player.x, update.x, constants.NET_PARAMS.VARIANCE_POSITION) or
		not within_variance(player_state.player.y, update.y, constants.NET_PARAMS.VARIANCE_POSITION) then
		--USE PCALL/XPCALL HERE TO "TRY" RETROACTIVE UPDATE, IF FAIL -> APPLY UPDATE DIRECTLY??
			retroactive_player_state_calc(update)
		else
			apply_retroactive_updates(update)
		end
	else
		--print("player state is null [svr_tick: " .. update.server_tick.."][client_tick: " .. tick .. "]")
	end
end

function server_entity_update(entity, update)
	assert(update.x and update.y, "Undefined x or y coordinates for entity update")
	assert(update.entity_type, "Undefined entity_type value for entity update")
	assert(update.x_vel and update.y_vel, "Undefined x or y velocities for entity update")
    if update.entity_type == "PLAYER" or update.entity_type == "ENEMY" then
        assert(update.state, "Undefined state for entity update")
    end
	x, y, x_vel, y_vel = tonumber(update.x), tonumber(update.y), tonumber(update.x_vel), tonumber(update.y_vel)

    if update.entity_type == "PLAYER" or update.entity_type == "ENEMY" then
        local ent = world[entity]
    	if not ent then return nil end
    	ent = update_entity_state(ent, update.state)
        ent = update_entity(ent, x, y, x_vel, y_vel)
        world[entity] = ent
    elseif update.entity_type == "PROJECTILE" then
        local ent = world['projectiles'][entity]
    	if not ent then return nil end
        ent = update_entity(ent, x, y, x_vel, y_vel)
        world['projectiles'][entity] = ent
    end
end

function server_entity_create(entity)
	assert(entity.x, "Undefined x coordinate value for entity creation")
	assert(entity.y, "Undefined y coordinate value for entity creation")
	assert(entity.entity_type, "Undefined entity_type value for entity creation")
	--assert(entity.state, "Invalid state value for entity creation")
	x, y, x_vel, y_vel = tonumber(entity.x), tonumber(entity.y), tonumber(entity.x_vel), tonumber(entity.y_vel)

	add_entity(entity.alias, entity.entity_type, {
        name = entity.alias,
        colour = entity.colour or nil,
        x=x, y=y, x_vel=x_vel or 0,
        y_vel=y_vel or 0, state=entity.state or nil,
        projectile_type = entity.projectile_type or nil
    })
end

function update_entities(dt)
	for name, entity in pairs(world) do
        if entity.entity_type == "PLAYER" then
            update_sprite_instance(entity.sprite_instance, dt)
        elseif entity.entity_type == "ENEMY" then
			update_entity_movement(dt, entity, constants.PLAYER_FRICTION, false, false)
            update_sprite_instance(entity.sprite_instance, dt)
        end
	end
    for id, projectile in pairs(world["projectiles"]) do
        if projectile.entity_type == "PROJECTILE" then
            local vel = projectile.velocity:angleTo(vector(0,-1))
            dbg("proj vel x:" ..projectile.velocity.x .. " y: " .. projectile.velocity.y .. " angle: " .. vel)
            update_sprite_instance(projectile.sprite_instance, dt, vel)
            --print("updating projectile")
        end
    end
end

function update_entity(entity, x, y, x_vel, y_vel)
    if entity.entity_type == "PROJECTILE" then
        entity.velocity.x = x_vel
        entity.velocity.y = y_vel
    elseif entity.entity_type == "ENEMY" then
        --nothing special 4 now
    end

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

function update_entity_movement(dt, entity, friction, isPlayer, isRetroactive)
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
		if isPlayer then
			if not isRetroactive then
				update_player_state("STAND")
			else
				entity.state = "STAND"
			end
		end
	end

	return entity
end

function prepare_camera(x, y, zoom)
	camera = Camera(x, y)
	camera:zoomTo(zoom)
end

function update_camera()
	local camX, camY = camera:position()
	local newX, newY = camX, camY

	if point_is_in_rectangle(player.x, player.y,
	  round_to_nth_decimal(camX - love.graphics.getWidth()*cameraBoxWidth - 1, 2), round_to_nth_decimal(camY - love.graphics.getHeight()*cameraBoxHeight - 1,2),
	  round_to_nth_decimal(love.graphics.getWidth()*cameraBoxWidth*2 + 2,2),  round_to_nth_decimal(love.graphics.getHeight()*cameraBoxHeight*2 + 2), 2) then
		if not within_variance(player.x, camX, 3) and
		 	 not within_variance(player.y, camY, 3) then
			newX = math.clamp(player.x, minCamX, maxCamX)
			newY = math.clamp(player.y, minCamY, maxCamY)
			camera:lockPosition(newX, newY, camera.smooth.damped(0.6))
		end
	else
		if (player.x > camX + love.graphics.getWidth()*cameraBoxWidth) then
			newX = player.x - love.graphics.getWidth()*cameraBoxWidth
		end
		if (player.x < camX - love.graphics.getWidth()*cameraBoxWidth) then
			newX = player.x + love.graphics.getWidth()*cameraBoxWidth
		end
		if (player.y > camY + love.graphics.getHeight()*cameraBoxHeight) then
			newY = player.y - love.graphics.getHeight()*cameraBoxHeight
		end
		if (player.y < camY - love.graphics.getHeight()*cameraBoxHeight) then
			newY = player.y + love.graphics.getHeight()*cameraBoxHeight
		end

		newX = math.clamp(newX, minCamX,maxCamX)
		newY = math.clamp(newY, minCamY,maxCamY)
		camera:lockPosition(newX, newY, camera.smooth.damped(10))
	end
end

function update_camera_boundaries()
	minCamX = 0 + love.graphics.getWidth()/camera.scale/2
	minCamY = 0 + love.graphics.getHeight()/camera.scale/2
	maxCamX = stage.width*stage.tilewidth - love.graphics.getWidth()/camera.scale/2
	maxCamY = stage.height*stage.tileheight -love.graphics.getHeight()/camera.scale/2
end
