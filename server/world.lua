world = {} -- the empty world-state
world["players"] = {} -- player collection
world["entities"] = {} -- projectile collection
deleted = {} -- buffer table of entity delete message to send to all clients

current_stage = {}
local STAGE_WIDTH_TILES = nil
local STAGE_HEIGHT_TILES = nil
local STAGE_WIDTH_TOTAL = nil
local STAGE_HEIGHT_TOTAL = nil

function load_stage()
  if not file_exists("stages/"..config.STAGE) then
    if pcall(dofile, "stages/"..config.STAGE..".lua") then
      current_stage = dofile("stages/"..config.STAGE..".lua")
      STAGE_WIDTH_TILES = current_stage.width
      STAGE_HEIGHT_TILES = current_stage.height
      STAGE_WIDTH_TOTAL = STAGE_WIDTH_TILES * current_stage.tilewidth
      STAGE_HEIGHT_TOTAL = STAGE_HEIGHT_TILES * current_stage.tileheight
      print("Loaded stage: '" .. config.STAGE .. "' succesfully")
    else
      print("[ERROR] Failed to load stage. " .. config.STAGE .. " File is incorrect format or corrupt")
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
	if entity.velocity.x and entity.velocity.y then --why is this componenatlised
        entity.x = math.clamp(round_to_nth_decimal(entity.x + entity.velocity.x*dt, 2), 0, STAGE_WIDTH_TOTAL or 100)
		entity.y = math.clamp(round_to_nth_decimal(entity.y + entity.velocity.y*dt, 2), 0, STAGE_HEIGHT_TOTAL or 100)
	end
    entity.hitbox:moveTo(entity.x, entity.y)
    world[id] = entity
	end
end

function remove_player(entity)
	if not world["players"][entity] then return end
	local ent = world["players"][entity]
	if ent.entity_type == "PLAYER" then
		table.insert(unused_colours, ent.colour)
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

function spawn_projectile(x, y, velocity_vector, owner)
    print("[DEBUG] Spawning projectile with owner: " .. owner)
    local new_projectile = {
        position = vector(x,y),
        velocity = velocity_vector,
        acceleration = 600,
        entity_type = "PROJECTILE",
        projectile_type = "FIREBALL",
        owner = owner,
        width = 14,
        height = 19
    }

    local id = random_string(12)

    new_projectile.hitbox = HC.rectangle(x, y, 14, 19)
    new_projectile.hitbox.owner = owner
    new_projectile.hitbox.type = new_projectile.entity_type
    new_projectile.hitbox:rotate(velocity_vector:angleTo(vector(0,-1))) --should this be angleTo(0,0)?
    local hbx1, hby1, hbx2, hby2 = new_projectile.hitbox:bbox()
    print("x1: " .. hbx1 .. " y1: " .. hby1 .. " x2: " .. hbx2 .. " y2: " .. hby2 )
    world["entities"][id] = new_projectile
    --TODO: Start player cooldown (and check the skill is ready in the first place)
    Timer.after(5, function()
        remove_entity(id)
    end)
    broadcast_debug_packet("+".. new_projectile.entity_type .. " " .. id,
        {x1=tostring(hbx1),y1=tostring(hby1),
        width=tostring(new_projectile.width),
        height=tostring(new_projectile.height),
        rotation=tostring(velocity_vector:angleTo(vector(0,-1)))
        }
    )
end

function process_collisions(dt)
    for alias, player in pairs(world["players"]) do
        --print_table(player, alias)
        for shape, delta in pairs(HC.collisions(player.hitbox)) do
            local d_vector = vector(delta.x,delta.y)
            local player_pos = vector(player.x, player.y)

            if shape.owner ~= alias then
                print(alias ..  " & [" .. shape.type .. "] " .. shape.owner ..  " Colliding. Separating vector = (" .. delta.x .. ",".. delta.y)
            end

            if shape.type == "PROJECTILE" then
                -- do collision stuff
            elseif shape.type == "PLAYER" then
                if shape.owner ~= alias then
                    -- apply delta force to
                    print_table(player)
                    player_pos = player_pos + d_vector * 1000 * dt
                    player.x = player_pos.x
                    player.y = player_pos.y
                    player.hitbox:moveTo(player_pos.x, player_pos.y)
                    --queue_correction(alias, payload, tick)
                    --send_client_correction_packet(player,)
                end
            end

            --you have OWNER and TYPE variables on the hitbox.
            --Look at warlocks SP, `entityHit()` in player.lua

        end
    end
end


function apply_player_position_update(ent, payload)
    ent.x = round_to_nth_decimal(tonumber(payload.x),2)
    ent.y = round_to_nth_decimal(tonumber(payload.y),2)
    ent.velocity = vector(round_to_nth_decimal(tonumber(payload.x_vel), 2), round_to_nth_decimal(tonumber(payload.y_vel),2))
    ent.state = payload.state
    ent.orientation = payload.orientation or ent.orientation

    world["players"][payload.alias] = ent
end
