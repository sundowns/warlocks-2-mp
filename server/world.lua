world = {} -- the empty world-state
world["players"] = {} -- player collection
world["entities"] = {} -- projectile collection
deleted = {} -- buffer table of entity delete message to send to all clients

current_stage = {}
local STAGE_WIDTH_TILES = nil
local STAGE_HEIGHT_TILES = nil
local STAGE_WIDTH_TOTAL = nil
local STAGE_HEIGHT_TOTAL = nil
STAGE_HASH = nil

Entity = Class{
    init = function(self, position, width, height)
        self.position = position
        self.width = width
        self.height = height
    end;
    move = function(self, inX, inY)
        self.position = vector(inX, inY)
    end;
}

function load_stage()
  if not file_exists("stages/"..config.STAGE) then
    if pcall(dofile, "stages/"..config.STAGE..".lua") then
      current_stage = dofile("stages/"..config.STAGE..".lua")
      STAGE_WIDTH_TILES = current_stage.width
      STAGE_HEIGHT_TILES = current_stage.height
      STAGE_WIDTH_TOTAL = STAGE_WIDTH_TILES * current_stage.tilewidth
      STAGE_HEIGHT_TOTAL = STAGE_HEIGHT_TILES * current_stage.tileheight
      STAGE_HASH = md5.sumhexa(tostring(current_stage))
      log("Loaded stage: '" .. config.STAGE .. "' succesfully")
    else
      log("[ERROR] Failed to load stage. " .. config.STAGE .. " File is incorrect format or corrupt")
    end
  end
end

function update_entity_positions(dt)
	update_player_positions(dt)

    for id,entity in pairs(world["entities"]) do
        if entity.entity_type == 'PROJECTILE' then
            entity.position = entity.position + entity.velocity:normalized() * entity.acceleration * dt
            if entity.position.x < 0 or entity.position.x > STAGE_WIDTH_TOTAL or
                entity.position.y < 0 or entity.position.y > STAGE_HEIGHT_TOTAL then
                remove_entity(id)
            else
                entity.hitbox:moveTo(entity.position.x, entity.position.y)
            end
        end
    end
end

function update_player_positions(dt)
    for id, entity in pairs(world["players"]) do
    	if entity.velocity then
            entity:move(math.clamp(round_to_nth_decimal(entity.position.x + entity.velocity.x*dt, 2), 0, STAGE_WIDTH_TOTAL or 100),
                math.clamp(round_to_nth_decimal(entity.position.y + entity.velocity.y*dt, 2), 0, STAGE_HEIGHT_TOTAL or 100)
            )
    	end
    end
end

function remove_player(entity)
	if not world["players"][entity] then return end
	local ent = world["players"][entity]
	if ent.entity_type == "PLAYER" then
		table.insert(unused_colours, ent.colour)
        --HC.remove(ent.hitbox)
		world["players"][entity] = nil
	end
    table.insert(deleted, {id = entity, entity_type = ent.entity_type})
end

function remove_entity(id)
    local ent = world["entities"][id]
    if ent ~= nil then
        table.insert(deleted, {id = id, entity_type = ent.entity_type})
        world["entities"][id] = nil
    end
end



--http://gamedev.stackexchange.com/questions/3884/should-collision-detection-be-done-server-side-or-cooperatively-between-client-s
-- Do collision detection mostly on the CLIENT and just use the server to verify when necessary
-- ur game isnt gonna be a AAA eSport so dont waste your life trying to make it bulletproof!

function process_collisions(dt)
    for alias, player in pairs(world["players"]) do
        for shape, delta in pairs(HC.collisions(player.hitbox)) do
            if shape.type == "PROJECTILE" then
                -- do collision stuff
            elseif shape.type == "PLAYER" then
                if shape.owner ~= alias then
                    log("shape owner: " .. shape.owner .. " player alias: " .. alias)
                    players_colliding(player, shape.owner, delta, dt)
                end
            end
            --Look at warlocks SP, `entityHit()` in player.lua

        end
    end
end


--PLAYER 1 WILL ALWAYSSSSSSSSSSS BE THE PLAYER WHO JOINED LAST, SO THE LOGIC MUSTTTTTTTT!!
--BE BASED PURELY OFF OF MATHS USING EACH PLAYERS VELOCITIES, WE DONT KNOW "WHO RAN INTO WHO"

--http://blog.wolfire.com/2009/07/linear-algebra-for-game-developers-part-2/ DOT product maybe useful here??
function players_colliding(player1, other_player_alias, collision_vector, dt)
    if player1.hasCollidedWith[other_player_alias] then return end -- If they're already colliding
    local player2 = world["players"][other_player_alias]
    if player2 == nil then return end -- can happen if players collide as one is disconnecting
    if player2.hasCollidedWith[player1.name] then return end

    local d_vector = vector(collision_vector.x,collision_vector.y)
    local resultant_velocity = player1.velocity + player2.velocity
    local resultant_magnitude = resultant_velocity:len()*50

    local p1_delta = d_vector
    local p2_delta = d_vector:clone()

    if player1.velocity:len() > player2.velocity:len() then
        p1_delta = -1 * p1_delta
    else
        p2_delta = -1 * p2_delta
    end

    --TODO: Work out collision logic once u have server updates working correctly
    --local player1_pos = vector(player1.x, player1.y)
    player1.velocity = player1.velocity + p1_delta:normalized()*resultant_magnitude
    log("colliding n shit")
    --player1_pos = player1_pos + (player1.velocity + (d_vector * resultant_magnitude) * dt)
    --player1 = move_player(player1, player1_pos.x, player1_pos.y)

    --local player2_pos = vector(player2.x, player2.y)
    player2.velocity = player2.velocity + p2_delta:normalized()*resultant_magnitude
    --player2_pos = player2_pos + (player2.velocity + (d_vector * resultant_magnitude) * dt)
    --player2 = move_player(player2, player2_pos.x, player2_pos.y)

    player1.hasCollidedWith[player2.name] = true
    player2.hasCollidedWith[player1.name] = true
    Timer.after(0.2, function()
        player1.hasCollidedWith[player2.name] = false
        if world["players"][player2.name] ~= nil then
            world["players"][player2.name].hasCollidedWith[player1.name] = false
        end
    end)

    world["players"][player2.name] = player2 -- Dont need to update player 1 because it is already a reference to the table
    send_client_correction_packet(host:get_peer(player1.index), player1.name, false)
    send_client_correction_packet(host:get_peer(player2.index), player2.name, false)
    log("p1: " .. player1.index .. " " .. player1.name .. " p2: " .. player2.index .. " " .. player2.name) -- The list iterates in reverse order??? (not a biggy, just surprising)
    --queue_correction(player1.name, tick)
    --queue_correction(player2.name, tick)
end

function apply_player_position_update(ent, payload)
    ent.position.x = round_to_nth_decimal(tonumber(payload.x),2)
    ent.position.y = round_to_nth_decimal(tonumber(payload.y),2)
    ent.state = payload.state
    ent.orientation = payload.orientation or ent.orientation

    world["players"][payload.alias] = ent
end

function apply_player_velocity_update(ent, payload)
    world["players"][payload.alias].velocity = vector(round_to_nth_decimal(tonumber(payload.x_vel), 2), round_to_nth_decimal(tonumber(payload.y_vel),2))
end
