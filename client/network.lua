local enet = require "enet"
local server
local host
connected = false

--local socket = require "socket"
local address, port = "localhost", "12345"
updateRate = 0.05 -- how long to wait, in seconds, before requesting an update
worldTime = 0 -- timer

function net_initialise()
	print("connecting")
	host = enet.host_create()
	server = host:connect(address..':'..port)
	--udp = socket.udp()
	--udp:settimeout(0)
	--udp:setpeername(address, port)
	worldTime = 0
end

function listen()
	print("rtt: " ..server:round_trip_time())
	return host:service(100)
end

function confirm_join()
	print("WE JOINING")
	server:send(create_json_packet({client_version = client_version}, "JOIN", username))
	connected = true
end

function disconnect(msg)
	if not connected then return end
	--server:send(create_json_packet({msg = msg}, "DISCONNECT", username))
	server:disconnect()
	host:flush()
end

function send_player_update(inPlayer, inName)
	if not connected then return end
	server:send(create_json_packet(inPlayer, "MOVE", inName))
end
