local socket = require "socket"
local udp = socket.udp()

udp:settimeout(0)
assert(udp:setsockname('*', 12345)) 

local world = {} -- the empty world-state
local data, msg_or_ip, port_or_nil
local entity, cmd, params

local running = true
local updateRate = 0.15 -- Update world timer in seconds (6.67 times a second)
local t = 0
local prevTime = socket.gettime()

local clientList = {}

function send_world_update(ip, port)
	for k, v in pairs(world) do
		udp:sendto(string.format("%s %s %d %d", k, "entity_at", v.x, v.y), ip,  port)
	end
end

function update_entity_positions(dt)
	for id, ent in pairs(world) do
		if ent.x_vel and ent.y_vel then
			world[id].x = ent.x + ent.x_vel*dt
			world[id].y = ent.y + ent.y_vel*dt
		end
	end
end

print("Beginning server loop.")
while running do
	local time = socket.gettime()
	local dt = time - prevTime

	data, msg_or_ip, port_or_nil = udp:receivefrom()
	if data then
		entity, cmd, params = data:match("^(%S*) (%S*) (.*)")
		if cmd == 'move' then --for now I dont think we need this, movement all calc'd w/ velocity on server
			-- local x, y = params:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
			-- assert(x and y) -- validation is better, but asserts will serve for now.
			-- x, y = tonumber(x), tonumber(y)
			-- local ent = world[entity] or {x=0,y=0}
			-- world[entity] = {x=ent.x+x, y=ent.y+y}
		elseif cmd == "velocity" then
			local x_vel, y_vel = params:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
			assert(x_vel and y_vel)
			x_vel, y_vel = tonumber(x_vel), tonumber(y_vel)
			local ent = world[entity]
			world[entity] = {x_vel = x_vel, y_vel = y_vel, x=ent.x, y=ent.y}
		elseif cmd == 'join' then
			if (not clientList[entity]) then --New client joining! Lets send em all our world data
				table.insert(clientList, {ip=msg_or_ip, port=port_or_nil, name=entity})
				print(entity .. ' has joined the server, sending world update')
				send_world_update(msg_or_ip, port_or_nil)
				world[entity] = {x_vel=0,y_vel=0,x=0,y=0}
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

	local prevTime = time
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

