world = {}
world["projectiles"] = {}
local minCamX = 0
local minCamY = 0
local maxCamX = 2000
local maxCamY = 2000
cameraBoxHeight = 0.035
cameraBoxWidth = 0.05

--Abstract class inherited directly by Player and Projectile
Entity = Class{
    init = function(self, name, position, velocity, entity_type, state)
        self.name = name
        self.position = position
        self.velocity = velocity
        self.entity_type = entity_type
        self.state = state
        self.sprite_instance = {}
    end;
    move = function(self, new)
        self.position = vector(new.x, new.y)
    end;
    updateState = function(self, newState, isRetroactive)
        if self.state ~= newState then
    		 self.state = newState
             if not isRetroactive then
                 self.sprite_instance.curr_anim = newState
                 self.sprite_instance.curr_frame = 1
             end
    	 end
    end;
}

function add_entity(name, entity_type, ent)
	if entity_type == "PLAYER" then
		if ent.name == settings.username then
			world[name] = ent
		else
			add_enemy(name, ent)
		end
    elseif entity_type == "PROJECTILE" then
        add_projectile(ent)
	end
end

function remove_entity(name, entity_type)
    if entity_type == "PLAYER" then
        if world[name] then
    		world[name] = nil
    	end
    elseif entity_type == "PROJECTILE" then
        if world['projectiles'][name] ~= nil then
            world['projectiles'][name] = nil
        end
    end
end

function add_enemy(name, enemy)
    local new_enemy = Enemy(vector(enemy.x, enemy.y), name, enemy.colour,
     "STAND", "RIGHT", 22, 20, vector(enemy.x_vel, enemy.y_vel))
	world[name] = new_enemy
end

function add_projectile(ent)
    if ent.projectile_type == "FIREBALL" then
        add_fireball(ent)
    end
end

function add_fireball(ent)
    local fireball = Fireball(ent.name, vector(ent.x, ent.y), vector(ent.x_vel, ent.y_vel),
        ent.height, ent.width
    )
    world["projectiles"][fireball.name] = fireball
end

function server_player_update(update, force_retroactive)
	assert(update.x and update.y, "Undefined x or y coordinates for player update")
	assert(update.entity_type, "Undefined entity_type value for player update")
	assert(update.x_vel and update.y_vel, "Undefined x or y velocities for player update")
	update.x = tonumber(update.x)
	update.y = tonumber(update.y)
	update.x_vel = tonumber(update.x_vel)
	update.y_vel = tonumber(update.y_vel)
	local player_state = player_state_buffer:get(tonumber(update.server_tick))
	if player_state then
		if force_retroactive then
            retroactive_player_state_calc(update)
        else
            -- If the server's representation of us is within acceptable variance of our own
            if within_variance(player_state.player.position.x, update.x, constants.NET_PARAMS.VARIANCE_POSITION) and
    		within_variance(player_state.player.position.y, update.y, constants.NET_PARAMS.VARIANCE_POSITION) then
                --do nothing
            else
                --try retro, else do manual override
                if not pcall(retroactive_player_state_calc, update) then
                    apply_player_updates(update)
                end
            end
        end
	else
		--print("failed player_state condition")
        dbg("player state is null [svr_tick: " .. update.server_tick.."][client_tick: " .. tick .. "][largest buffer tick ".. player_state_buffer.current_max_tick .. "]")
	end
end

function server_entity_update(entity, update)
	assert(update.x and update.y, "Undefined x or y coordinates for entity update")
	assert(update.entity_type, "Undefined entity_type value for entity update")
	assert(update.x_vel and update.y_vel, "Undefined x or y velocities for entity update")
    if update.entity_type == "PLAYER" or update.entity_type == "ENEMY" then
        assert(update.state, "Undefined state for entity update")
        assert(update.orientation, "Undefined orientation for entity update")
    end
	x, y, x_vel, y_vel = tonumber(update.x), tonumber(update.y), tonumber(update.x_vel), tonumber(update.y_vel)

    if update.entity_type == "PLAYER" or update.entity_type == "ENEMY" then
        local ent = world[entity]
    	if not ent then return nil end
    	ent:updateState(update.state)
        ent = update_entity(ent, x, y, x_vel, y_vel, update.orientation or nil)
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
	x, y, x_vel, y_vel = tonumber(entity.x), tonumber(entity.y), tonumber(entity.x_vel), tonumber(entity.y_vel)
    width, height = tonumber(entity.width), tonumber(entity.height)
	add_entity(entity.alias, entity.entity_type, {
        name = entity.alias,
        colour = entity.colour or nil,
        x=x, y=y, x_vel=x_vel or 0,
        y_vel=y_vel or 0, state=entity.state or nil,
        projectile_type = entity.projectile_type or nil,
        width = entity.width or 0, height = entity.height or 0
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
    for id, projectile in ipairs(world["projectiles"]) do
        if projectile.entity_type == "PROJECTILE" then
            local rotation = projectile.velocity:angleTo(vector(0,-1))
            update_sprite_instance(projectile.sprite_instance, dt, rotation)
            --print("updating projectile")
        end
    end
end

function update_entity(entity, x, y, x_vel, y_vel, orientation)
    -- if entity.entity_type == "PROJECTILE" then
    --     entity.velocity.x = x_vel
    --     entity.velocity.y = y_vel
    -- elseif entity.entity_type == "ENEMY" then
    --     if orientation then entity.orientation = orientation end
    -- end

	entity:move(vector(round_to_nth_decimal(x, 2), round_to_nth_decimal(y, 2)))
    entity.orientation = orientation
	entity.velocity.x = round_to_nth_decimal(x_vel, 2) -- y dis?
	entity.velocity.y = round_to_nth_decimal(y_vel, 2)
	return entity
end

function update_entity_movement(dt, entity, friction, isPlayer, isRetroactive)
    if isRetroactive then
        entity.position.x = round_to_nth_decimal((entity.position.x + (entity.velocity.x * dt)),2)
    	entity.position.y = round_to_nth_decimal((entity.position.y + (entity.velocity.y * dt)),2)
    else
        entity:move(vector(round_to_nth_decimal((entity.position.x + (entity.velocity.x * dt)),2),
            round_to_nth_decimal((entity.position.y + (entity.velocity.y * dt)),2)))
    end

    local friction_vector = entity.velocity*-1
    friction_vector:normalizeInplace()

	if entity.velocity:len() < 3 then
		entity.velocity = vector(0, 0)
		if isPlayer then
			if not isRetroactive then
				entity:updateState("STAND")
			else
				entity.state = "STAND"
			end
		end
    else
        -- apply friction
        entity.velocity = entity.velocity + friction_vector * friction * dt
	end

	return entity
end

function process_collisions(dt)
    for shape, delta in pairs(HC.collisions(player.hitbox)) do
        if shape.type == "PROJECTILE" then
            -- do collision stuff
        elseif shape.type == "PLAYER" then
            --colliding_with_player(dt)
            --send a packet sayin we collided ?
            player:collidingWithEnemy(dt, world[shape.owner], vector(delta.x, delta.y))
        elseif shape.type == "OBJECT" then
            player:collidingWithObject(dt, vector(delta.x, delta.y))
            if shape.properties["collide_projectiles"] then
                print("dis collides with projecties")
            end
        end
        --Look at warlocks SP, `entityHit()` in player.lua
    end
end


-- function players_colliding(player1, other_player_alias, collision_vector, dt)
--     if player1.hasCollidedWith[other_player_alias] then return end -- If they're already colliding
--     local player2 = world["players"][other_player_alias]
--     if player2 == nil then return end -- can happen if players collide as one is disconnecting
--     if player2.hasCollidedWith[player1.name] then return end
--
--     local d_vector = vector(collision_vector.x,collision_vector.y)
--     local resultant_velocity = player1.velocity + player2.velocity
--     local resultant_magnitude = resultant_velocity:len()*50
--
--     local p1_delta = d_vector
--     local p2_delta = d_vector:clone()
--
--     if player1.velocity:len() > player2.velocity:len() then
--         p1_delta = -1 * p1_delta
--     else
--         p2_delta = -1 * p2_delta
--     end
--
--     --TODO: Work out collision logic once u have server updates working correctly
--     --local player1_pos = vector(player1.x, player1.y)
--     player1.velocity = player1.velocity + p1_delta:normalized()*resultant_magnitude
--     log("colliding n shit")
--     --player1_pos = player1_pos + (player1.velocity + (d_vector * resultant_magnitude) * dt)
--     --player1 = move_player(player1, player1_pos.x, player1_pos.y)
--
--     --local player2_pos = vector(player2.x, player2.y)
--     player2.velocity = player2.velocity + p2_delta:normalized()*resultant_magnitude
--     --player2_pos = player2_pos + (player2.velocity + (d_vector * resultant_magnitude) * dt)
--     --player2 = move_player(player2, player2_pos.x, player2_pos.y)
--
--     player1.hasCollidedWith[player2.name] = true
--     player2.hasCollidedWith[player1.name] = true
--     Timer.after(0.2, function()
--         player1.hasCollidedWith[player2.name] = false
--         if world["players"][player2.name] ~= nil then
--             world["players"][player2.name].hasCollidedWith[player1.name] = false
--         end
--     end)
--
--     world["players"][player2.name] = player2 -- Dont need to update player 1 because it is already a reference to the table
--     send_client_correction_packet(host:get_peer(player1.index), player1.name, false)
--     send_client_correction_packet(host:get_peer(player2.index), player2.name, false)
--     log("p1: " .. player1.index .. " " .. player1.name .. " p2: " .. player2.index .. " " .. player2.name) -- The list iterates in reverse order??? (not a biggy, just surprising)
--     --queue_correction(player1.name, tick)
--     --queue_correction(player2.name, tick)
-- end

function prepare_camera(x, y, zoom)
    if love.window.getFullscreen() then
        zoom = zoom * 2
    end
	camera = Camera(x, y)
	camera:zoomTo(zoom)
end

function update_camera()
	local camX, camY = camera:position()
	local newX, newY = camX, camY

	if point_is_in_rectangle(player.position.x, player.position.y,
	  round_to_nth_decimal(camX - love.graphics.getWidth()*cameraBoxWidth - 1, 2), round_to_nth_decimal(camY - love.graphics.getHeight()*cameraBoxHeight - 1,2),
	  round_to_nth_decimal(love.graphics.getWidth()*cameraBoxWidth*2 + 2,2),  round_to_nth_decimal(love.graphics.getHeight()*cameraBoxHeight*2 + 2), 2) then
		if not within_variance(player.position.x, camX, 3) and
		 	 not within_variance(player.position.y, camY, 3) then
			newX = math.clamp(player.position.x, minCamX, maxCamX)
			newY = math.clamp(player.position.y, minCamY, maxCamY)
			camera:lockPosition(newX, newY, camera.smooth.damped(0.6))
		end
	else
		if (player.position.x > camX + love.graphics.getWidth()*cameraBoxWidth) then
			newX = player.position.x - love.graphics.getWidth()*cameraBoxWidth
		end
		if (player.position.x < camX - love.graphics.getWidth()*cameraBoxWidth) then
			newX = player.position.x + love.graphics.getWidth()*cameraBoxWidth
		end
		if (player.position.y > camY + love.graphics.getHeight()*cameraBoxHeight) then
			newY = player.position.y - love.graphics.getHeight()*cameraBoxHeight
		end
		if (player.position.y < camY - love.graphics.getHeight()*cameraBoxHeight) then
			newY = player.position.y + love.graphics.getHeight()*cameraBoxHeight
		end

		newX = math.clamp(newX, minCamX,maxCamX)
		newY = math.clamp(newY, minCamY,maxCamY)
		camera:lockPosition(newX, newY, camera.smooth.damped(10))
	end
end

function update_camera_boundaries()
	minCamX = 0 + love.graphics.getWidth()/camera.scale/2
	minCamY = 0 + love.graphics.getHeight()/camera.scale/2
    if stage ~= nil then
        maxCamX = stage.width*stage.tilewidth - love.graphics.getWidth()/camera.scale/2
    	maxCamY = stage.height*stage.tileheight -love.graphics.getHeight()/camera.scale/2
    else
        maxCamX = 100 - love.graphics.getWidth()/camera.scale/2
        maxCamY = 100 - love.graphics.getHeight()/camera.scale/2
    end

end
