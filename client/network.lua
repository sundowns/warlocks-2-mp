local socket = require "socket"
local address, port = "localhost", 12345
updateRate = 0.05 -- how long to wait, in seconds, before requesting an update
worldTime = 0 -- timer

function net_initialise()
	udp = socket.udp()
	udp:settimeout(0)
	udp:setpeername(address, port)
	worldTime = 0
end

function request_join()
	udp:send(create_json_packet({client_version = client_version}, "JOIN", username))
end

function disconnect(msg)
	udp:send(create_json_packet({msg = msg}, "DISCONNECT", username))
	udp:close()
end