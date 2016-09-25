local enet = require "enet"
local server
local host
connected = false

--local socket = require "socket"
local address, port = "localhost", "12345"
updateTimer = 0 -- timer for network updates
worldTime = 0 -- timer

function net_initialise()
	host = enet.host_create()
	server = host:connect(address..':'..port)
	worldTime = 0
end

function listen(timeout)
	if timeout == nil then timeout = 0 end
	--dbg("rtt: " ..server:last_round_trip_time())
	return host:service(timeout)
end

function confirm_join()
	print("my name is " .. settings.username)
	server:send(create_json_packet({client_version = constants.CLIENT_VERSION}, "JOIN", tick, settings.username))
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
	server:send(create_json_packet(inPlayer, "PLAYERUPDATE", tick, inName))
end

--DONT USE JSON, USE SOME BINARY SERIALISATION OR SUMMIN. JSON IS SLOW
function create_json_packet(payload, cmd, tick, alias)
  if alias then payload.alias = alias end
  payload.cmd = cmd
	payload.client_tick = tick
  return json.encode(payload)
end
