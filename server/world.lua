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
            local delta = entity.velocity * dt
            entity.position = entity.position + delta
            if entity.position.x < 0 or entity.position.x > STAGE_WIDTH_TOTAL or
                entity.position.y < 0 or entity.position.y > STAGE_HEIGHT_TOTAL then
                remove_entity(id)
            else
                entity.hitbox:moveTo(entity.position.x, entity.position.y)
                --TODO: delete dis
                local x1,y1,x2,y2,x3,y3,x4,y4 = entity.hitbox._polygon:unpack()
                broadcast_debug_packet("+".. entity.entity_type .. " " .. id, {
                    x1=tostring(x1),y1=tostring(y1),
                    x2=tostring(x2),y2=tostring(y2),
                    x3=tostring(x3),y3=tostring(y3),
                    x4=tostring(x4),y4=tostring(y4)
                    }
                )
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
        HC.remove(ent.hitbox)
		world["players"][entity] = nil
	end
    table.insert(deleted, {id = entity, entity_type = ent.entity_type})
end

function remove_entity(id)
    local ent = world["entities"][id]
    if ent ~= nil then
        table.insert(deleted, {id = id, entity_type = ent.entity_type})
        if world["entities"][id].hitbox ~= nil then
            HC.remove(world["entities"][id].hitbox)
        end
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

                if shape.owner ~= alias then
                    player:hitByProjectile(shape.owner, world["entities"][shape.id], vector(delta.x, delta.y), dt)
                    world["entities"][shape.id]:hitEnemy()
                    remove_entity(shape.id)
                    --remove_entity(shape.parent)
                end
            -- elseif shape.type == "PLAYER" then
                -- if shape.owner ~= alias then
                --
                --     --players_colliding(player, shape.owner, delta, dt)
                -- end
            end
            --Look at warlocks SP, `entityHit()` in player.lua

        end
    end
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
