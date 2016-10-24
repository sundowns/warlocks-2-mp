world = {} -- the empty world-state
world["players"] = {} -- player collection
deleted = {} -- buffer table of entity delete message to send to all clients
selected_stage = "arena1"
current_stage = {}
local STAGE_WIDTH = 48
local STAGE_HEIGHT = 48

function load_stage()
  if not file_exists("stages/"..selected_stage) then
    if pcall(dofile, "stages/"..selected_stage..".lua") then
      current_stage = dofile("stages/"..selected_stage..".lua")
      print("Loaded stage succesfully")
    else
      print("[ERROR] Failed to load stage. " .. selected_stage .. " File is incorrect format or corrupt")
    end
  end
end

function update_entity_positions(dt)
  --print("updating player positions")
	for id, entity in pairs(world["players"]) do
		if entity.x_vel and entity.y_vel then
			entity.x = round_to_nth_decimal(entity.x + entity.x_vel*dt, 2)
			entity.y = round_to_nth_decimal(entity.y + entity.y_vel*dt, 2)
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
