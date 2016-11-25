world = {} -- the empty world-state
world["players"] = {} -- player collection
deleted = {} -- buffer table of entity delete message to send to all clients
selected_stage = "arena1"
current_stage = {}
local STAGE_WIDTH_TILES = nil
local STAGE_HEIGHT_TILES = nil
local STAGE_WIDTH_TOTAL = nil
local STAGE_HEIGHT_TOTAL = nil

function load_stage()
  if not file_exists("stages/"..selected_stage) then
    if pcall(dofile, "stages/"..selected_stage..".lua") then
      current_stage = dofile("stages/"..selected_stage..".lua")
      STAGE_WIDTH_TILES = current_stage.width
      STAGE_HEIGHT_TILES = current_stage.height
      STAGE_WIDTH_TOTAL = STAGE_WIDTH_TILES * current_stage.tilewidth
      STAGE_HEIGHT_TOTAL = STAGE_HEIGHT_TILES * current_stage.tileheight
      print("Loaded stage succesfully")
    else
      print("[ERROR] Failed to load stage. " .. selected_stage .. " File is incorrect format or corrupt")
    end
  end
end

function update_entity_positions(dt)
	update_player_positions(dt)
end

function update_player_positions(dt)
  for id, entity in pairs(world["players"]) do
		if entity.x_vel and entity.y_vel then
			entity.x = math.clamp(round_to_nth_decimal(entity.x + entity.x_vel*dt, 2), 0, STAGE_WIDTH_TOTAL)
			entity.y = math.clamp(round_to_nth_decimal(entity.y + entity.y_vel*dt, 2), 0, STAGE_HEIGHT_TOTAL)
		end
    world[id] = entity
	end
end

function remove_entity(entity)
	if not world["players"][entity] then return end
	local ent = world["players"][entity]
	if ent.entity_type == "PLAYER" then
		table.insert(unused_colours, ent.colour)
		world["players"][entity] = nil
	end
	deleted[entity] = {entity_type = ent.entity_type}
end
