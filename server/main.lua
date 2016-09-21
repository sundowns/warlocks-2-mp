package.path = './?.lua;' .. package.path

require "socket" -- to keep track of time
json = require("json")
local enet = require "enet"
local host = enet.host_create("localhost:12345")
--host:bandwidth_limit(1024000, 1024000)

server_version = "0.0.1"
require("util")

local client_player_map = {} -- look up player alias' by client ip
local world = {} -- the empty world-state
world["players"] = {} -- player collection

local deleted = {} -- buffer table of entity delete message to send to all clients
local running = true
local t = 0
local prevTime = os.time()
local tick = 0
local tickrate = 0.015625 --64 tick
local tick_timer = 0
local updateRate = 8 -- send world updates every 16 ticks

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

	local entId = client_player_map[peer:connect_id()]
	if world["players"][entId] ~= nil then
		remove_entity(entId)
	end

	clientList[peer:connect_id()] = nil
	client_count = client_count - 1
	peer:disconnect()
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
	-- if dt < 1/60 then -- 60 fps limit
	-- 	love.timer.sleep(1/60 - dt)
	-- end
	--print(client_count)
	time = socket.gettime()
	local dt = time - prevTime
	prevTime = time
	tick_timer = tick_timer + dt

	if tick_timer > tickrate then
		tick = tick + 1
		tick_timer = 0
		--print("tick. " .. tick)
		local event = host:service()
		while event ~= nil do
			if event.type == "receive" then
				if not xpcall(json.decode, event.data) then
					payload = json.decode(event.data)
					--print("receiving packet cmd: " ..payload.cmd)
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
							if ent then
								world["players"][payload.alias] = {x_vel = payload.x_vel, y_vel = payload.y_vel, x=round_to_nth_decimal(payload.x,2), y=round_to_nth_decimal(payload.y,2), colour = ent.colour, entity_type = ent.entity_type}
							else
								print("tried to MOVE non existing player. " .. payload.alias)
							end
						end
					elseif payload.cmd == 'JOIN' then
						if tostring(payload.client_version) ~= server_version then
							send_error_packet(event.peer, "Incorrect version. Server is running " .. server_version)
							remove_client(event.peer, event.peer .. " version " .. payload.client_version .. " conflicts with server version " .. server_version)
						elseif client_count > max_clients then
							send_error_packet(event.peer, "Game is full.")
							remove_client(event.peer, "Game is full.")
						else
							clientList[event.peer].name = payload.alias
							send_world_update(event.peer, payload.alias)
							if world["players"][payload.alias] then
								send_error_packet(event.peer, "The alias " .. payload.alias .. " is already in use.")
								remove_client(payload.alias, "Duplicate alias")
							else
								world["players"][payload.alias] = {x_vel=0,y_vel=0,x=0,y=0, entity_type = "PLAYER", colour = clientList[event.peer].colour }
								client_player_map[event.peer:connect_id()] = payload.alias
							end
						end
					elseif payload.cmd == 'UPDATE' then
						print('[WARNING] Explicitly requested world update received. Potential security risk.')
					else
						print("[WARNING] unrecognised command: " .. payload.cmd)
					end
				else
					print("Failed to JSON decode packet: " .. tostring(event.data))
				end
			elseif event.type == "connect" then
					local colour = table.remove(unused_colours)
					clientList[event.peer] =  {ip=msg_or_ip, port=port_or_nil, name=nil, time_since_last_msg = 0, colour = colour}
					client_count = client_count + 1
					print(event.peer:connect_id() .. ' connected.')
					send_join_accept(event.peer, colour)
					for k, v in pairs(event) do
						print("k: " .. k .. " v: " .. tostring(v))
					end
			elseif event.type == "disconnect" then
				remove_client(event.peer,  clientList[event.peer].name .." disconnected. Closed by user")
				--error("Network error: " .. tostring(msg_or_ip))
			end
			event = host:service()
		end

		update_entity_positions(dt)
		if tick%updateRate == 0 then
			send_world_update()
			deleted = {}
		end
	end

	--update_client_timeout(dt)
	--socket.sleep(0.01) -- prevents CPU from going HAM
end

host:disconnect()
