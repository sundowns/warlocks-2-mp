local enet = require "enet"
local server
local host
last_rtt = 0
last_offset = 1
connected = false
connection_is_new = true
connected_time = 0

--local socket = require "socket"
local address, port = "localhost", "12345"
updateTimer = 0 -- timer for network updates

function net_initialise()
	host = enet.host_create()
	server = host:connect(address..':'..port)
end

function listen(timeout)
	if timeout == nil then timeout = 0 end
	return host:service(timeout)
end

function sync_client(server_tick)
	if connection_is_new then
		last_rtt = constants.NET_PARAMS.STABILISATION_RTT
	else
		last_rtt = server:last_round_trip_time()
	end
	offset = math.min(math.floor(last_rtt/1000/constants.TICKRATE+1), 2)
	tick = server_tick + offset -- server tick + ticks per RTT + 1
	last_offset = offset
end

function confirm_join()
	print("my name is " .. settings.username)
	server:round_trip_time(10)
	tick = payload.server_tick
	server:send(create_binary_packet({client_version = constants.CLIENT_VERSION}, "JOIN", tick, settings.username))
	connected = true
end

function disconnect(msg)
		if msg then print(msg) end
		server:disconnect()
		host:flush()
		connected = false
		GamestateManager.switch(error, msg)
end

function send_player_update(inPlayer, inName)
	if not connected then return end
	local playerVM = {
		x = inPlayer.x,
		y = inPlayer.y,
		state = inPlayer.state,
		acceleration = inPlayer.acceleration,
		x_vel = inPlayer.x_vel,
		y_vel = inPlayer.y_vel
	}
	server:send(create_binary_packet(playerVM, "PLAYERUPDATE", tick, inName))
end

function send_action_packet(action, data)
    if not connected then return end
    server:send(create_binary_packet(data, action, tick, settings.username))
end

function display_net_info()
	love.graphics.setColor(0, 255, 100)
	set_font(12, 'debug')
	if connected then
		love.graphics.print("rtt: "..last_rtt, camera:worldCoords(3,0))
		if connection_is_new then
			love.graphics.print("stabilising...", camera:worldCoords(70,0))
		end
	else
		love.graphics.print("Disconnected.", camera:worldCoords(3,0))
	end
	reset_colour()
end

function update_connection(dt)
	if connected then
		connected_time = connected_time + dt
		if connection_is_new and connected_time > constants.NET_PARAMS.STABILISATION_TIME then
			connection_is_new = false
		end
	end
end

packet_meta = {}
function packet_meta.__index(table, key)
  --print("im doing stuff")
  if key == 'alias' then
    return table[4]
  elseif key == 'cmd'then
    return table[3]
	elseif key == 'server_tick' or key == 'tick' then
		return table[2]
  else
    return table[1][key]
  end
end

function create_binary_packet(payload, cmd, tick, alias)
	return binser.serialize(payload, tostring(tick), cmd, alias)
end

function verify_player_correction_packet(payload)
    local update = {
        x = tonumber(payload.x),
        y = tonumber(payload.y),
        x_vel = tonumber(payload.x_vel),
        y_vel = tonumber(payload.y_vel),
        state = payload.state,
        colour = payload.colour
    }
    local verified = true
    if not assert(update.x) then verified = false print("Failed to verify x update for player") end
    if not assert(update.y) then verified = false print("Failed to verify y update for player") end
    if not assert(update.x_vel) then verified = false print("Failed to verify x_vel update for player") end
    if not assert(update.y_vel) then verified = false print("Failed to verify y_vel update for player") end
    if not assert(update.state) or not type(update.state) == 'string' then verified = false print("Failed to verify state update for player") end
    if not assert(update.colour) or not type(update.colour) == 'string' then verified = false print("Failed to verify colour update for player") end
    return verified, update
end

function verify_spawn_packet(payload)
    local update = {
        x = tonumber(payload.x),
        y = tonumber(payload.y),
        x_vel = tonumber(payload.x_vel),
        y_vel = tonumber(payload.y_vel),
        entity_type = payload.entity_type,
        state = payload.state,
        dash = payload.dash,
        colour = payload.colour,
        orientation = payload.orientation,
        name = payload.name,
        width = tonumber(payload.width),
        height = tonumber(payload.height),
        max_movement_velocity = tonumber(payload.max_movement_velocity),
        acceleration = tonumber(payload.acceleration),
        movement_friction = tonumber(payload.movement_friction),
        base_acceleration = tonumber(payload.base_acceleration)
    }

    local verified = true
    if not assert(update.x) then verified = false print("Failed to verify x for player spawn packet") end
    if not assert(update.y) then verified = false print("Failed to verify y for player spawn packet") end
    if not assert(update.x_vel) then verified = false print("Failed to verify x_vel for player spawn packet") end
    if not assert(update.y_vel) then verified = false print("Failed to verify y_vel for player spawn packet") end
    if not assert(update.entity_type  == 'PLAYER') or not type(update.entity_type) == 'string' then verified = false print("Failed to verify entity_type for player spawn packet") end
    if not assert(update.state) or not type(update.state) == 'string' then verified = false print("Failed to verify state for player spawn packet") end
    if not assert(update.colour) or not type(update.colour) == 'string' then verified = false print("Failed to verify colour for player spawn packet") end
    if not assert(update.orientation) or not type(update.orientation) == 'string' then verified = false print("Failed to verify orientation for player spawn packet") end
    if not assert(update.name) or not type(update.name) == 'string' then verified = false print("Failed to verify name for player spawn packet") end
    if not assert(update.width) then verified = false print("Failed to verify width for player spawn packet") end
    if not assert(update.height) then verified = false print("Failed to verify height for player spawn packet") end
    if not assert(update.dash) or not type(update.name) == 'table' then verified = false print("Failed to verify dash for player spawn packet") end
    if not assert(update.max_movement_velocity) then verified = false print("Failed to verify max_movement_velocity for player spawn packet") end
    if not assert(update.acceleration) then verified = false print("Failed to verify acceleration for player spawn packet") end
    if not assert(update.movement_friction) then verified = false print("Failed to verify movement_friction for player spawn packet") end
    if not assert(update.base_acceleration) then verified = false print("Failed to verify base_acceleration for player spawn packet") end
    return verified, update
end
