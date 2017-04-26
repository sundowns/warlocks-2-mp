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

SpawnManager = Class {
    init = function(self, spawns, count)
        self.spawns = spawns
        self.total_spawns = count
    end;
    spawn = function(self, name, client_index)
        local colour =  client_list[client_index].colour
        local spawn_point = table.remove(self.spawns, 1)
    	local new_player = Player(name, vector(spawn_point.x, spawn_point.y),colour, client_index)
        new_player:addSpell(Fireball())
        table.insert(self.spawns, spawn_point)
    	world["players"][name] = new_player
        return world["players"][name]
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
      load_stage_data()
      log("Loaded stage: '" .. config.STAGE .. "' succesfully")
    else
      log("[ERROR] Failed to load stage. " .. config.STAGE .. " File is incorrect format or corrupt")
    end
  end
end

function load_stage_data()
    local collidablesLayerExists = false
    local spawnLayerExists = false
    local collidablesCount = 0
    local spawnsCount = 0
    for i, layer in ipairs(current_stage.layers) do
        if layer.type == "objectgroup" then
            if layer.name == "Collidable Objects" then
                collidablesLayerExists = true
                for j, object in ipairs(layer.objects) do
                    object.hitbox = HC.rectangle(object.x, object.y, object.width, object.height)
                    object.hitbox.type = "OBJECT"
                    object.hitbox.owner = "__WORLD"
                    object.hitbox.properties = object.properties
                    collidablesCount = collidablesCount + 1
                end
            elseif layer.name == "Player Spawns" then
                spawnLayerExists = true
                local spawns = {}
                for j, object in ipairs(layer.objects) do
                    table.insert(spawns, {x = object.x, y = object.y})
                    spawnsCount = spawnsCount + 1
                end
                spawnManager = SpawnManager(spawns, spawnsCount)
            end
        end
    end
    log("Loaded " .. collidablesCount .. " collidable objects")
    log("Loaded " .. spawnsCount .. " player spawn points")
end

-- function spawn_player(name, client_index)
--     local colour =  client_list[client_index].colour
--     local spawn_point = table.remove(spawns, 1)
-- 	local new_player = Player(name, vector(spawn_point.x, spawn_point.y),colour, client_index)
--     table.insert(spawns, spawn_point)
-- 	world["players"][payload.alias] = new_player
--
-- 	return new_player
-- end

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
    local markedForDeletion = {}

    for id, ent in pairs(world["entities"]) do
        if ent.entity_type == "PROJECTILE" then
            for shape, delta in pairs(HC.collisions(ent.hitbox)) do
                if shape.type == "OBJECT" and shape.properties["collide_projectiles"] then
                    if not ent.dirty then
                        ent:hitObject(shape.owner, vector(-1*delta.x, -1*delta.y), shape._polygon.centroid) --bit yolo but eh we good ok
                        table.insert(markedForDeletion, id)
                        ent.dirty = true
                    end
                elseif shape.type == "PLAYER" then
                    if not ent.dirty and ent.owner ~= shape.owner and not ent.hitbox.collided_with[shape.owner] then
                        local hitPlayer = world["players"][shape.owner]
                        if hitPlayer then
                            hitPlayer:hitByProjectile(ent.owner, ent)
                        end
                        ent:hitObject(shape.owner, vector(-1*delta.x, -1*delta.y), hitPlayer.position)
                        table.insert(markedForDeletion, id)
                        ent.dirty = true
                    end
                end
            end
        end
    end

    for i,v in ipairs(markedForDeletion) do
        remove_entity(v)
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
