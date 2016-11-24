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

function display_net_info()
	love.graphics.setColor(0, 255, 100)
	set_font_size(12)
	if connected then
		love.graphics.print("RTT: "..last_rtt, camera:worldCoords(3,20))
		if connection_is_new then
			set_font_size(10)
			love.graphics.print("stabilising...", camera:worldCoords(3,35))
		end
	else
		love.graphics.print("Disconnected.", camera:worldCoords(3,20))
	end
	reset_colour()
	reset_font()
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
	return binser.serialize(payload, tick, cmd, alias)
end

--DONT USE JSON, USE SOME BINARY SERIALISATION OR SUMMIN. JSON IS SLOW
function create_json_packet(payload, cmd, tick, alias)
  if alias then payload.alias = alias end
  payload.cmd = cmd
	payload.client_tick = tick
  return json.encode(payload)
end
