local socket = require "socket"
local address, port = "localhost", 12345
updateRate = 0.10 -- how long to wait, in seconds, before requesting an update
worldTime = 0 -- timer

function net_initialise()
	udp = socket.udp()
	udp:settimeout(0)
	udp:setpeername(address, port)
	worldTime = 0
end

function request_join()
	local joindg = string.format("%s %s %d", player.name, 'join', 1)
	udp:send(joindg)
end