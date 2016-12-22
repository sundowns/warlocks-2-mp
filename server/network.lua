client_count = 0
client_list = {}
client_player_map = {} -- look up player alias' by client ip
packet_meta = {} -- meta table for decoding binary packets

function send_world_update()
	for k, player in pairs(world["players"]) do
		local payload = create_player_payload(player)
		local ok, packet = pcall(create_binary_packet, payload, "ENTITYUPDATE", tick, k)
		if ok then
			host:broadcast(packet)
		else
			print("Error sending player " .. k .. " world update. Dumping data:")
			print_table(payload)
			print("----------")
		end
	end

    for id, entity in pairs(world["entities"]) do
        local payload = create_entity_payload(entity)
        local ok, packet = pcall(create_binary_packet, payload, "ENTITYUPDATE", tick, id)
		if ok then
			host:broadcast(packet)
		else
			print("Error sending projectile " .. id .. " during world update. Dumping data:")
			print_table(payload)
			print("----------")
		end
    end

	for i, v in ipairs(deleted) do
		host:broadcast(create_binary_packet(v, "ENTITYDESTROY", tostring(tick), v.id))
	end
end

function create_player_payload(player)
	return {x = tostring(player.x), y = tostring(player.y),
        x_vel = tostring(round_to_nth_decimal(player.velocity.x,2)),
        y_vel = tostring(round_to_nth_decimal(player.velocity.y,2)),
        colour = player.colour, entity_type = "PLAYER",
        state = player.state,
        width = tostring(player.width),
        height = tostring(player.height),
        orientation = tostring(player.orientation)
    }
end

function create_spawn_player_payload(player)
    return {
		x = player.x,
		y = player.y,
	  	name = player.name,
	  	entity_type = "PLAYER",
	  	state = "STAND",
		orientation = "RIGHT",
        x_vel = player.x_vel,
        y_vel = player.y_vel,
	  	max_movement_velocity = player.max_movement_velocity,
	  	movement_friction = player.movement_friction,
		base_acceleration = player.base_acceleration,
		acceleration = player.acceleration,
		dash = player.dash,
        width = player.width,
	  	height = player.height,
	  	colour = player.colour
  	}
end

function create_entity_payload(entity)
    return {x = tostring(round_to_nth_decimal(entity.position.x,2)), y = tostring(round_to_nth_decimal(entity.position.y)),
        x_vel = tostring(round_to_nth_decimal(entity.velocity.x,2)),
        y_vel = tostring(round_to_nth_decimal(entity.velocity.y,2)),
        entity_type = entity.entity_type,
        projectile_type = entity.projectile_type or nil,
        width = entity.width or 0,
        height = entity.height or 0
    }
end

function send_error_packet(peer, message)
	local data = { message = message }
	peer:send(create_binary_packet(data, "SERVERERROR", tick))
end

function send_spawn_packet(peer, player)
    print(player.name .. " spawned.")
	peer:send(create_binary_packet(create_spawn_player_payload(player), "SPAWN", tick))
end

function broadcast_debug_packet(message, extra_data)
    local data = {message = message}
    if extra_data then
        data = merge_tables(data, extra_data)
    end

	host:broadcast(create_binary_packet(data, "DEBUG", tick))
end

function send_join_accept(peer, colour)
	peer:send(create_binary_packet({colour = colour, stage_name = config.STAGE}, "JOINACCEPTED", tick))
end

function send_client_correction_packet(peer, alias)
    if world["players"][alias] then
        peer:send(create_binary_packet(create_player_payload(world["players"][payload.alias]), "PLAYERCORRECTION", tick))
    else
        print("[ERROR] Attempted to send correction packet to non-existent player: " .. payload.alias)
    end
end

function remove_client(peer, msg)
    if peer == nil then return end
	if (msg) then print(msg) end
	local entId = client_player_map[peer]
	if entId then
		remove_player(entId)
	end

	client_list[peer] = nil
	client_count = client_count - 1
    pcall(peer.disconnect)
	--peer:disconnect()
end

function update_client_timeout(dt)
	for k, v in pairs(client_list) do
		v.time_since_last_msg = v.time_since_last_msg + dt
		if v.time_since_last_msg > constants.CLIENT_TIMEOUT then
			remove_client(k, v.name.." user timed out")
		end
	end
end

function packet_meta.__index(table, key)
  if key == 'alias' then
    return table[4]
  elseif key == 'cmd'then
    return table[3]
	elseif key == 'client_tick' or key == 'tick' then
		return table[2]
  else
    return table[1][key]
  end
end

function create_binary_packet(payload, cmd, tick, alias)
	return binser.serialize(payload, tostring(tick), cmd, alias)
end

function verify_position_update(old, new)
  local accept_update = true
	if not within_variance(old.x, new.x, constants.NET_PARAMS.VARIANCE_POSITION) then
		accept_update = false
		print("ruh roh, x not within variance. old: " .. old.x .. " new: " .. new.x)
	elseif not within_variance(old.y, new.y, constants.NET_PARAMS.VARIANCE_POSITION) then
		accept_update = false
		print("ruh roh, y not within variance. old: " .. old.y .. " new: " .. new.y)
	end
	return accept_update
end
