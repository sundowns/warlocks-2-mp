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
	local joindg = string.format("%s %s %s", username, 'JOIN', clientVersion)
	udp:send(joindg)
end

function disconnect(msg)
	local disconnectdg = string.format("%s %s %s", player.name, 'DISCONNECT', msg)
	udp:send(disconnectdg)
	udp:close()
end