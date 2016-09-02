package.path = './?.lua;' .. package.path

json = require("json")
local enet = require "enet"
local host = enet.host_create("localhost:12345")
host:bandwidth_limit(1024000, 1024000)

--local socket = require "socket"
--local udp = socket.udp()

server_version = "0.0.1"
require("util")

--udp:settimeout(0)
--assert(udp:setsockname('*', 12345))
--local data, msg_or_ip, port_or_nil
--local entity, cmd, params

local client_player_map = {} -- look up player alias' by client ip
local world = {} -- the empty world-state
world["players"] = {} -- player collection
local deleted = {} -- buffer table of entity delete message to send to all clients
local running = true
local updateRate = 0.1 -- Update world timer in seconds (6.67 times a second)
local t = 0
local prevTime = os.time()
local tick = 0

local unused_colours = {"green", "purple", "red"}
local max_clients = 3
local client_count = 0
local clientList = {}
local clientTimeOut = 10

function send_world_update()
	for k, v in pairs(world["players"]) do
		host:broadcast(create_json_packet(v, "ENTITYAT", k)) -- YOU NEED SOME LOGIC FOR ENEMY VS PLAYER? ON CLIENT SIDE?
	end

	for k, v in pairs(deleted) do
		host:broadcast(create_json_packet(v, "ENTITYDESTROY", k))
	end
end

function send_error_packet(peer, message)
	local data = { message = message}
	peer:send(create_json_packet(data, "SERVERERROR"))
end

function send_join_accept(peer, colour)
	peer:send(create_json_packet({colour = colour , server_tick = tick}, "JOINACCEPTED"))
end

function remove_client(peer, msg)
	if (msg) then print(msg) end
	clientList[peer] = nil
	client_count = client_count - 1
end

-- function update_client_timeout(dt)
-- 	for k, v in pairs(clientList) do
-- 		v.time_since_last_msg = v.time_since_last_msg + dt
-- 		if v.time_since_last_msg > clientTimeOut then
-- 			remove_client(k, k.." user timed out")
-- 			remove_entity(k)
-- 		end
-- 	end
-- end

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

print("Beginning server loop.")
while running do
	local event = host:service(100)
	local time = os.time()
	local dt = time - prevTime
	prevTime = time
	tick = tick + 1

	--data, msg_or_ip, port_or_nil = udp:receivefrom()

	if not event then
		--do nothing (wait somehow maybe idk)
	elseif event.type == "receive" then
		if not xpcall(json.decode, event.data) then
			payload = json.decode(event.data)
			if not assert(payload.alias) then print(tostring(payload)) end
			if clientList[event.peer] then
				clientList[event.peer].time_since_last_msg = 0
			end
			assert(payload.cmd)
			--print("cmd: " ..payload.cmd)
			if payload.cmd == "MOVE" then
				if clientList[event.peer] then
					assert(payload.x_vel and payload.y_vel and payload.x and payload.y)
					local ent = world["players"][payload.alias]
					world["players"][payload.alias] = {x_vel = payload.x_vel, y_vel = payload.y_vel, x=round_to_nth_decimal(payload.x,2), y=round_to_nth_decimal(payload.y,2), colour = ent.colour, entity_type = ent.entity_type}
				end
			elseif payload.cmd == 'JOIN' then
				print("do we eva join")
				if tostring(payload.client_version) ~= server_version then
					send_error_packet(msg_or_ip, port_or_nil, "Incorrect version. Server is running " .. server_version)
				elseif client_count >= max_clients then
					send_error_packet(msg_or_ip, port_or_nil, "Game is full.")
				else
					print("adding new dude " .. payload.alias)
					clientList[event.peer].name = payload.alias
					send_world_update(event.peer, payload.alias)
					if world["players"][payload.alias] then
						send_error_packet(event.peer, "The alias " .. payload.alias .. " is already in use.")
						remove_client(payload.alias, "Duplicate alias")
					else
						world["players"][payload.alias] = {x_vel=0,y_vel=0,x=0,y=0, entity_type = "PLAYER", colour = colour}
						client_player_map[event.peer] = payload.alias
					end
				end
			--elseif payload.cmd == 'DISCONNECT' then
				-- remove_client(payload.alias, payload.alias .. " disconnected. " .. payload.msg)
				-- remove_entity(payload.alias)
			elseif payload.cmd == 'UPDATE' then
				print('[WARNING] Explicitly requested world update received. Potential security risk.')
			else
				print("[WARNING] unrecognised command: " .. payload.cmd)
			end
		else
			print("Failed to JSON decode packet: " .. tostring(event.data))
		end
	elseif event.type == "connect" then
			print("hello")
			clientList[event.peer] =  {ip=msg_or_ip, port=port_or_nil, name=nil, time_since_last_msg = 0}
			client_count = client_count + 1
			print(event.peer:connect_id() .. ' connected.')
			local colour = table.remove(unused_colours)
			send_join_accept(event.peer, colour)
	elseif event.type == "disconnect" then
		remove_client(event.peer, payload.alias .. " disconnected. " .. payload.msg)
		remove_entity(client_player_map[event.peer])
		--error("Network error: " .. tostring(msg_or_ip))
	end

	t = t+dt
	if t > updateRate then
		send_world_update()
		deleted = {}
		t = t - updateRate
	end
	update_entity_positions(dt)
	--update_client_timeout(dt)
	event = host:service()
	--socket.sleep(0.01) -- prevents CPU from going HAM
end

--udp:close()
