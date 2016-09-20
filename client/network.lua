local enet = require "enet"
local server
local host
connected = false

--local socket = require "socket"
local address, port = "localhost", "12345"
netUpdateRate = 8 -- Every 8 ticks (64/4 = 16)
updateTimer = 0 -- timer for network updates
worldTime = 0 -- timer

function net_initialise()
	dbg("connecting")
	host = enet.host_create()
	server = host:connect(address..':'..port)
	worldTime = 0
end

function listen(timeout)
	if timeout == nil then timeout = 0 end
	--print("rtt: " ..server:round_trip_time())
	return host:service(timeout)
end

function confirm_join()
	print("my name is " .. username)
	server:send(create_json_packet({client_version = client_version}, "JOIN", username))
	connected = true
end

function disconnect(msg)
	if not connected then return end
	if msg then print(msg) end
	server:disconnect()
	host:flush()
end

function send_player_update(inPlayer, inName)
	if not connected then return end
	server:send(create_json_packet(inPlayer, "MOVE", inName))
end
