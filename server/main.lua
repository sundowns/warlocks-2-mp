package.path = './?.lua;' .. package.path 

local socket = require "socket"
local udp = socket.udp()
server_version = "0.0.1"
require("util")

udp:settimeout(0)
assert(udp:setsockname('*', 12345)) 
local data, msg_or_ip, port_or_nil
local entity, cmd, params

local world = {} -- the empty world-state
local deleted = {}
local running = true
local updateRate = 0.05 -- Update world timer in seconds (6.67 times a second)
local t = 0
local prevTime = socket.gettime()
tick = 0

local unused_colours = {"green", "purple", "red"} --add red back once u make user request colour on join
local clientList = {}
local clientTimeOut = 10

function send_world_update(ip, port, name)
	for k, v in pairs(world) do
		local entity_type = v.entity_type
		if v.entity_type == "PLAYER" then
			if name ~= k then
				entity_type = "ENEMY"
			end
		end
		local data = {v.x, v.y, entity_type, v.colour}
		udp:sendto(build_packet(k, "ENTITYAT", data), ip,  port)
	end

	for k, v in pairs(deleted) do
		local data = {v.entity_type}
		udp:sendto(build_packet(k, "ENTITYDESTROY", data), ip, port)
	end
	print("world update sent to " .. name .." ip: " .. ip .. " port: " ..port)
end

function send_error_packet(ip, port, message)
	udp:sendto(string.format("%s %s", "SERVERERROR", message), ip,  port)
end

function send_join_accept(ip, port, entity, colour)
	udp:sendto(build_packet(entity, "JOINACCEPTED", {colour}), ip,  port)
end

function remove_client(client, msg)
	if (msg) then print(msg) end
	clientList[client] = nil
end

function update_client_timeout(dt)
	for k, v in pairs(clientList) do
		v.time_since_last_msg = v.time_since_last_msg + dt
		if v.time_since_last_msg > clientTimeOut then
			remove_client(k, "user timed out")
			remove_entity(k)
		end
	end
end

function update_entity_positions(dt)
	for id, ent in pairs(world) do
		if ent.x_vel and ent.y_vel then
			world[id].x = round_to_nth_decimal(ent.x + ent.x_vel*dt, 2) 
			world[id].y = round_to_nth_decimal(ent.y + ent.y_vel*dt, 2)
		end
	end
end

function remove_entity(entity)
	if not world[entity] then return end
	local ent = world[entity]
	if ent.entity_type == "PLAYER" then
		table.insert(unused_colours, ent.colour)
	end
	deleted[entity] = {entity_type = ent.entity_type}
	world[entity] = nil
end

print("Beginning server loop.")
while running do
	tick = tick + 1
	local time = socket.gettime()
	local dt = time - prevTime
	prevTime = time
	data, msg_or_ip, port_or_nil = udp:receivefrom()
	if data then
		entity, cmd, params = data:match("^(%S*) (%S*) (.*)")
		if clientList[entity] then
			clientList[entity].time_since_last_msg = 0
		end
		if cmd == "MOVE" then
			if clientList[entity] then
				local x, y, x_vel, y_vel = params:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*)$")
				assert(x_vel and y_vel and x and y)
				x_vel, y_vel = tonumber(x_vel), tonumber(y_vel)
				local ent = world[entity]
				world[entity] = {x_vel = x_vel, y_vel = y_vel, x=x, y=y, colour = ent.colour, entity_type = ent.entity_type}
			end
		elseif cmd == 'JOIN' then
			if tostring(params) ~= server_version then
				send_error_packet(msg_or_ip, port_or_nil, "Incorrect version. Server is running " .. server_version)
			else
				if (not clientList[entity]) then 
					clientList[entity] =  {ip=msg_or_ip, port=port_or_nil, name=entity, time_since_last_msg = 0}
					print(entity .. ' connected.')
					local colour = table.remove(unused_colours)
					send_join_accept(msg_or_ip, port_or_nil, entity, colour)
					send_world_update(msg_or_ip, port_or_nil, entity)
					if world[entity] then
						send_error_packet(msg_or_ip, port_or_nil, "The alias " .. entity .. " is already in use.")
						remove_client(entity, "Duplicate alias")
					else
						world[entity] = {x_vel=0,y_vel=0,x=0,y=0, entity_type = "PLAYER", colour = colour}
					end	
				end
			end
		elseif cmd == 'DISCONNECT' then	
			remove_client(entity, entity .. " disconnected. " .. tostring(params))
			remove_entity(entity)
		elseif cmd == 'UPDATE' then
			print('[WARNING] Explicitly requested world update received. Potential security risk.')
		else 
			print("unrecognised command: " .. tostring(cmd))
		end		
	elseif msg_or_ip == "closed" then
		--print("Client closed") --swallow these, timeout should take care of it
	elseif msg_or_ip ~= "timeout" then
		error("Network error: " .. tostring(msg_or_ip))
	end

	t = t+dt
	if t > updateRate then
		for id, client in pairs(clientList) do
			send_world_update(client.ip, client.port, client.name)
		end
		deleted = {}
		t = t - updateRate
	end
	update_entity_positions(dt)
	update_client_timeout(dt)
	socket.sleep(0.01) -- prevents CPU from going HAM
end

udp:close()