package.path = './?.lua;' .. package.path 

local socket = require "socket"
json = require("json")

local udp = socket.udp()
server_version = "0.0.1"
require("util")

udp:settimeout(0)
assert(udp:setsockname('*', 12345)) 
local data, msg_or_ip, port_or_nil
local entity, cmd, params

local world = {} -- the empty world-state
world["players"] = {} -- player collection
local deleted = {} -- buffer table of entity delete message to send to all clients
local running = true
local updateRate = 0.05 -- Update world timer in seconds (6.67 times a second)
local t = 0
local prevTime = socket.gettime()
local tick = 0

local unused_colours = {"green", "purple", "red"} --add red back once u make user request colour on join
local clientList = {}
local clientTimeOut = 10

function send_world_update(ip, port, name)
	for k, v in pairs(world["player"]) do
		local entity_type = v.entity_type
		if v.entity_type == "PLAYER" then
			print(k .. " " .. v.x .. " " .. v.y)
			if name ~= k then
				entity_type = "ENEMY"
			end
		end
		udp:sendto(create_json_packet(v, "ENTITYAT", k), ip,  port)
	end

	for k, v in pairs(deleted) do
		udp:sendto(create_json_packet(v, "ENTITYDESTROY", k), ip, port)
	end
end

function send_error_packet(ip, port, message)
	local data = { message = message}
	udp:sendto(create_json_packet(data, "SERVERERROR"), ip,  port)
end

function send_join_accept(ip, port, entity, colour)
	udp:sendto(create_json_packet({colour}, "JOINACCEPTED", entity), ip,  port)
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
	if not world["players"][entity] then return end
	local ent = world["players"][entity]
	if ent.entity_type == "PLAYER" then
		table.insert(unused_colours, ent.colour)
	end
	deleted[entity] = {entity_type = ent.entity_type}
	world["players"][entity] = nil
end

-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 
-- TRY ANOTHER JSON LIBRARY. ONE THAT LETS YOU TRY TO PARSE THINGS IN A CONDITION U FEEL -- 


print("Beginning server loop.")
while running do
	tick = tick + 1
	local time = socket.gettime()
	local dt = time - prevTime
	prevTime = time
	data, msg_or_ip, port_or_nil = udp:receivefrom()
	if data then
		--entity, cmd, params = data:match("^(%S*) (%S*) (.*)")
		if json.decode([[tostring(data)]]) then 
			payload = json.decode([[tostring(data)]]) 
				print(payload)
				if not assert(payload.alias) then print(tostring(payload)) end
				if clientList[payload.alias] then
					clientList[payload.alias].time_since_last_msg = 0
				end
				assert(payload.cmd)
				if payload.cmd == "MOVE" then
					if clientList[payload.alias] then
						--local x, y, x_vel, y_vel = params:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*)$")
						assert(payload.x_vel and payload.y_vel and payload.x and payload.y)
						--x_vel, y_vel = tonumber(x_vel), tonumber(y_vel)
						local ent = world["players"][payload.alias]
						world["players"][payload.alias] = {x_vel = payload.x_vel, y_vel = payload.y_vel, x=round_to_nth_decimal(payload.x,2), y=round_to_nth_decimal(payload.y,2), colour = ent.colour, entity_type = ent.entity_type}
					end
				elseif payload.cmd == 'JOIN' then
					if tostring(payload.client_version) ~= server_version then
						send_error_packet(msg_or_ip, port_or_nil, "Incorrect version. Server is running " .. server_version)
					else
						if (not clientList[payload.alias]) then 
							clientList[payload.alias] =  {ip=msg_or_ip, port=port_or_nil, name=payload.alias, time_since_last_msg = 0}
							print(payload.alias .. ' connected.')
							local colour = table.remove(unused_colours)
							send_join_accept(msg_or_ip, port_or_nil, payload.alias, colour)
							send_world_update(msg_or_ip, port_or_nil, payload.alias)
							if world["players"][payload.alias] then
								send_error_packet(msg_or_ip, port_or_nil, "The alias " .. payload.alias .. " is already in use.")
								remove_client(payload.alias, "Duplicate alias")
							else
								world["players"][payload.alias] = {x_vel=0,y_vel=0,x=0,y=0, entity_type = "PLAYER", colour = colour}
							end	
						end
					end
				elseif payload.cmd == 'DISCONNECT' then	
					remove_client(payload.alias, payload.alias .. " disconnected. " .. payload.msg)
					remove_entity(payload.alias)
				elseif payload.cmd == 'UPDATE' then
					print('[WARNING] Explicitly requested world update received. Potential security risk.')
				else 
					print("unrecognised command: " .. payload.cmd)
				end		
			elseif msg_or_ip == "closed" then
				--print("Client closed") --swallow these, timeout should take care of it
			elseif msg_or_ip ~= "timeout" then
				error("Network error: " .. tostring(msg_or_ip))
			end
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