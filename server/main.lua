local socket = require "socket"
local udp = socket.udp()
require('util')

udp:settimeout(0)
assert(udp:setsockname('*', 12345)) 

local world = {} -- the empty world-state
local data, msg_or_ip, port_or_nil
local entity, cmd, params

local running = true
local updateRate = 0.15 -- Update world timer in seconds (6.67 times a second)
local t = 0
local prevTime = socket.gettime()

local unused_colours = {"green", "purple"} --add red back once u make custom colours or sum shit

local clientList = {}
tick = 0

function send_world_update(ip, port)
	for k, v in pairs(world) do
		local packet = build_packet_string(k, "entity_at", v.x, v.y, v.entity_type, v.colour)
		udp:sendto(packet, ip,  port)
	end
end

function send_error_packet(ip, port, message)
	udp:sendto(string.format("%s %s", "server_error", message), ip,  port)
end

function remove_client(client)
	table.remove(clientList, client)
end

function update_entity_positions(dt)
	for id, ent in pairs(world) do
		if ent.x_vel and ent.y_vel then
			world[id].x = ent.x + ent.x_vel*dt
			world[id].y = ent.y + ent.y_vel*dt
		end
	end
end
--
--	WHEN YOU ADD TIMING OUT/DROPPING PLAYERS (AS YOU SHOULD) YOU NEED TO ADD THEIR COLOUR BACK TO THE UNUSED LIST  
--
--
--	WHEN YOU ADD TIMING OUT/DROPPING PLAYERS (AS YOU SHOULD) YOU NEED TO ADD THEIR COLOUR BACK TO THE UNUSED LIST  
--
--
--	WHEN YOU ADD TIMING OUT/DROPPING PLAYERS (AS YOU SHOULD) YOU NEED TO ADD THEIR COLOUR BACK TO THE UNUSED LIST  
--
--
--	WHEN YOU ADD TIMING OUT/DROPPING PLAYERS (AS YOU SHOULD) YOU NEED TO ADD THEIR COLOUR BACK TO THE UNUSED LIST  
----
--	WHEN YOU ADD TIMING OUT/DROPPING PLAYERS (AS YOU SHOULD) YOU NEED TO ADD THEIR COLOUR BACK TO THE UNUSED LIST  
----
--	WHEN YOU ADD TIMING OUT/DROPPING PLAYERS (AS YOU SHOULD) YOU NEED TO ADD THEIR COLOUR BACK TO THE UNUSED LIST  
----
--	WHEN YOU ADD TIMING OUT/DROPPING PLAYERS (AS YOU SHOULD) YOU NEED TO ADD THEIR COLOUR BACK TO THE UNUSED LIST  
----
--	WHEN YOU ADD TIMING OUT/DROPPING PLAYERS (AS YOU SHOULD) YOU NEED TO ADD THEIR COLOUR BACK TO THE UNUSED LIST  
----
--	WHEN YOU ADD TIMING OUT/DROPPING PLAYERS (AS YOU SHOULD) YOU NEED TO ADD THEIR COLOUR BACK TO THE UNUSED LIST  
----
--	WHEN YOU ADD TIMING OUT/DROPPING PLAYERS (AS YOU SHOULD) YOU NEED TO ADD THEIR COLOUR BACK TO THE UNUSED LIST  
----
--	WHEN YOU ADD TIMING OUT/DROPPING PLAYERS (AS YOU SHOULD) YOU NEED TO ADD THEIR COLOUR BACK TO THE UNUSED LIST  
--

print("Beginning server loop.")
while running do
	tick = tick + 1
	local time = socket.gettime()
	local dt = time - prevTime
	prevTime = time
	data, msg_or_ip, port_or_nil = udp:receivefrom()
	if data then
		entity, cmd, params = data:match("^(%S*) (%S*) (.*)")
		if cmd == "move" then
			local x, y, x_vel, y_vel = params:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*)$")
			assert(x_vel and y_vel and x and y)
			x_vel, y_vel = tonumber(x_vel), tonumber(y_vel)
			local ent = world[entity]
			world[entity] = {x_vel = x_vel, y_vel = y_vel, x=x, y=y, colour = ent.colour, entity_type = ent.entity_type}
		elseif cmd == 'join' then
			if (not clientList[entity]) then --New client joining! Lets send em all our world data
				table.insert(clientList, {ip=msg_or_ip, port=port_or_nil, name=entity})
				print(entity .. ' has joined the server, sending world update')
				send_world_update(msg_or_ip, port_or_nil)
				if world[entity] then
					send_error_packet(msg_or_ip, port_or_nil, "The name " .. entity .. " is already in use.")
					remove_client(client)
				else
					world[entity] = {x_vel=0,y_vel=0,x=0,y=0, entity_type = "PLAYER", colour = table.remove(unused_colours)}
				end	
			end
		elseif cmd == 'update' then
			print('[WARNING] Explicitly requested world update received. Potential security risk.')
		elseif cmd == 'kill' then
			running = false;
		else 
			print("unrecognised command: " .. tostring(cmd))
		end		
	elseif msg_or_ip ~= 'timeout' then
		error("Network error: " .. tostring(msg))
	end

	
	t = t+dt
	if t > updateRate then
		for id, client in pairs(clientList) do
			send_world_update(client.ip, client.port)
		end
		t = t - updateRate
	end
	update_entity_positions(dt)
	socket.sleep(0.01) -- prevents CPU from going HAM
end

udp:close()

