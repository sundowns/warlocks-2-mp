client_count = 0
client_list = {}
client_player_map = {} -- look up player alias' by client ip
packet_meta = {} -- meta table for decoding binary packets
client_corrections = {}

function queue_correction(alias, tick)
    local player = world["players"][alias]
    if player then
        local queue_item = {
            alias = alias,
            player = create_player_payload(player),
            tick = tick,
            client_index = player.index
        }
        table.insert(client_corrections, queue_item)
    end
end

function send_buffered_corrections()
    for i, v in ipairs(client_corrections) do
        send_client_correction_packet(host:get_peer(v.client_index), v.alias, true, v.tick)
    end
    client_corrections = {}
end

function send_world_update()
	for k, player in pairs(world["players"]) do
		local payload = create_player_payload(player)
		local ok, packet = pcall(create_binary_packet, payload, "ENTITYUPDATE", tick, k)
		if ok then
			host:broadcast(packet)
		else
			log("Error sending player " .. k .. " world update. Dumping data:")
			print_table(payload)
			log("----------")
		end
	end

    for id, entity in pairs(world["entities"]) do
        local payload = create_entity_payload(entity)
        local ok, packet = pcall(create_binary_packet, payload, "ENTITYUPDATE", tick, id)
		if ok then
			host:broadcast(packet)
		else
			log("Error sending projectile " .. id .. " during world update. Dumping data:")
			print_table(payload)
			log("----------")
		end
    end

	for i, v in ipairs(deleted) do
		host:broadcast(create_binary_packet(v, "ENTITYDESTROY", tostring(tick), v.id))
	end
end

function create_player_payload(player)
	return {
        x = tostring(player.position.x), y = tostring(player.position.y),
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
		x = player.position.x,
		y = player.position.y,
	  	name = player.name,
	  	entity_type = "PLAYER",
	  	state = "STAND",
		orientation = "RIGHT",
        x_vel = player.velocity.x,
        y_vel = player.velocity.y,
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
    log(player.name .. " spawned.")
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

function send_client_correction_packet(peer, alias, retroactive, tick_to_use)
    if not tick_to_use then tick_to_use = tick end
    if world["players"][alias] then
        local player_payload = create_player_payload(world["players"][alias])
        if retroactive then
            player_payload.retroactive = true
        else
            player_payload.retroactive = false
        end
        log("correction tick " .. tick_to_use)
        peer:send(create_binary_packet(player_payload, "PLAYERCORRECTION", tick_to_use))
    else
        log("[ERROR] Attempted to send correction packet to non-existent player: " .. alias)
    end
end

function remove_client(peer, msg)
    if peer == nil or peer.index == nil then return end
	if (msg) then log(msg) end
	local entId = client_player_map[peer:index()]
	if entId then
		remove_player(entId)
	end

	client_list[peer:index()] = nil
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
	if not within_variance(old.position.x, new.x, constants.NET_PARAMS.VARIANCE_POSITION) then
		accept_update = false
		log("x not within variance. old: " .. old.position.x .. " new: " .. new.x)
	elseif not within_variance(old.position.y, new.y, constants.NET_PARAMS.VARIANCE_POSITION) then
		accept_update = false
		log("y not within variance. old: " .. old.position.y .. " new: " .. new.y)
	end
	return accept_update
end

function verify_velocity_update(old, new)
    -- overriding this whole function for now cause fk u ok.
    local accept_update = true
	-- if not within_variance(old.velocity.x, new.x_vel, constants.NET_PARAMS.VARIANCE_VELOCITY) then
	-- 	accept_update = false
	-- 	log("x velocity component not within variance. old: " .. old.velocity.x .. " new: " .. new.x_vel)
	-- elseif not within_variance(old.velocity.y, new.y_vel, constants.NET_PARAMS.VARIANCE_VELOCITY) then
	-- 	accept_update = false
	-- 	log("y velocity component not within variance. old: " .. old.velocity.y .. " new: " .. new.y_vel)
	-- end
	return accept_update
end
