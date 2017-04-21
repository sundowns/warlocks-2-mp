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
      generate_tile_hitboxes()
      log("Loaded stage: '" .. config.STAGE .. "' succesfully")
    else
      log("[ERROR] Failed to load stage. " .. config.STAGE .. " File is incorrect format or corrupt")
    end
  end
end

function generate_tile_hitboxes()
    local collidablesLayerExists = false
    local count = 0
    for i, layer in ipairs(current_stage.layers) do
        if layer.type == "objectgroup" and layer.name == "Collidable Objects" then
            collidablesLayerExists = true
            for j, object in ipairs(layer.objects) do
                object.hitbox = HC.rectangle(object.x, object.y, object.width, object.height)
                object.hitbox.type = "OBJECT"
                object.hitbox.owner = "__WORLD"
                object.hitbox.properties = object.properties
                count = count + 1
            end
        end
    end
    log("Generated " .. count .. " map collision objects")
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
                entity.hitbox:move(delta.x, delta.y)
                --TODO: delete dis
                -- local x1,y1,x2,y2,x3,y3,x4,y4 = entity.hitbox._polygon:unpack()
                -- broadcast_debug_packet("+".. entity.entity_type .. " " .. id, {
                --     x1=tostring(x1),y1=tostring(y1),
                --     x2=tostring(x2),y2=tostring(y2),
                --     x3=tostring(x3),y3=tostring(y3),
                --     x4=tostring(x4),y4=tostring(y4),
                --     entX = tostring(entity.position.x),
                --     entY = tostring(entity.position.y)
                --     }
                -- )
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

function process_collisions(dt)
    for id, ent in pairs(world["entities"]) do
        if ent.entity_type == "PROJECTILE" then
            for shape, delta in pairs(HC.collisions(ent.hitbox)) do
                if shape.type == "OBJECT" and shape.properties["collide_projectiles"] then
                    ent:hitObject()
                    remove_entity(id)
                elseif shape.type == "PLAYER" then
                    if ent.owner ~= shape.owner then
                        ent:hitObject()
                        remove_entity(id)
                    end
                end
            end
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
