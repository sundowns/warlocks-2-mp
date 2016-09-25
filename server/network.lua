client_count = 0
client_list = {}
client_player_map = {} -- look up player alias' by client ip

function send_world_update()
	for k, player in pairs(world["players"]) do
		host:broadcast(create_json_packet(create_player_payload(player), "ENTITYUPDATE", tick, k))
	end

	for k, v in pairs(deleted) do
		host:broadcast(create_json_packet(v, "ENTITYDESTROY", tick, k))
	end
end

function create_player_payload(player)
	return {x = player.x, y = player.y, x_vel = player.x_vel, y_vel = player.y_vel, colour = player.colour, entity_type = "PLAYER", state = player.state}
end

function send_error_packet(peer, message)
	local data = { message = message}
	peer:send(create_json_packet(data, "SERVERERROR", tick))
end

function send_join_accept(peer, colour)
	peer:send(create_json_packet({colour = colour}, "JOINACCEPTED", tick))
end

function remove_client(peer, msg)
	if (msg) then print(msg) end

	local entId = client_player_map[peer]
	if entId then
		remove_entity(entId)
	end

	client_list[peer] = nil
	client_count = client_count - 1
	peer:disconnect()
end

function update_client_timeout(dt)
	for k, v in pairs(client_list) do
		v.time_since_last_msg = v.time_since_last_msg + dt
		if v.time_since_last_msg > constants.CLIENT_TIMEOUT then
			remove_client(k, v.name.." user timed out")
		end
	end
end

--DONT USE JSON ITS FKN SLOW NOOB. Use it to read settins file tho that's sexy
function create_json_packet(payload, cmd, tick, alias)
  if alias then payload.alias = alias end
	payload.server_tick = tick
  payload.cmd = cmd
  return json.encode(payload)
end
