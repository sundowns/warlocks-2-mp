package.path = './?.lua;' .. package.path

require "socket" -- to keep track of time
json = require("json")
constants = require("constants")
enet = require "enet"
host = enet.host_create("localhost:12345")
--host:bandwidth_limit(1024000, 1024000)

server_version = "0.0.1"
require("util")
require("network")

world = {} -- the empty world-state
world["players"] = {} -- player collection
deleted = {} -- buffer table of entity delete message to send to all clients
local running = true
local t = 0
local prevTime = socket.gettime()
tick = 0
local tick_timer = 0

local unused_colours = {"purple","green","red" }

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
		world["players"][entity] = nil
	end
	--table.insert(deleted, {entity_type = ent.entity_type})
	deleted[entity] = {entity_type = ent.entity_type}
end

print("Beginning server loop.")
while running do
	time = socket.gettime()
	local dt = time - prevTime
	prevTime = time
	tick_timer = tick_timer + dt

	if tick_timer > constants.TICKRATE then
		tick = tick + 1
		tick_timer = tick_timer - constants.TICKRATE
		local event = host:service()
		while event ~= nil do
			if event.type == "receive" then
				if not xpcall(json.decode, event.data) then
					payload = json.decode(event.data)
					if not assert(payload.alias) then print(tostring(payload)) end
					assert(client_list[event.peer])
					if client_list[event.peer] ~= nil then
						client_list[event.peer].time_since_last_msg = 0
					end
					assert(payload.cmd)
					if payload.cmd == "PLAYERUPDATE" then
						if client_list[event.peer] then
							assert(payload.client_tick)
							--print("received a msg from ".. payload.alias .. " at client_tick: " .. payload.client_tick .. " curr_svr_tick: " .. tick)
							assert(payload.x_vel and payload.y_vel and payload.x and payload.y and payload.state)
							local ent = world["players"][payload.alias]

							--TODO: VERIFY POSITION COORDINATES
							--TODO: VERIFY STATE CHANGE
							
							if ent then
								world["players"][payload.alias] = {x_vel = payload.x_vel, y_vel = payload.y_vel, x=round_to_nth_decimal(payload.x,2), y=round_to_nth_decimal(payload.y,2), colour = ent.colour, entity_type = ent.entity_type, state = payload.state}
							else
								print("tried to UPDATE non existing player. " .. payload.alias)
							end
						end
					elseif payload.cmd == 'JOIN' then
						if tostring(payload.client_version) ~= server_version then
							send_error_packet(event.peer, "Incorrect version. Server is running " .. server_version)
							remove_client(event.peer, event.peer .. " version " .. payload.client_version .. " conflicts with server version " .. server_version)
						else
							client_list[event.peer].name = payload.alias
							--send_world_update(event.peer, payload.alias)
							if world["players"][payload.alias] then
								send_error_packet(event.peer, "The alias " .. payload.alias .. " is already in use.")
								remove_client(payload.alias, "Duplicate alias")
							else
								client_player_map[event.peer] = payload.alias
								world["players"][payload.alias] = {x_vel=0,y_vel=0,x=0,y=0, entity_type = "PLAYER", colour = client_list[event.peer].colour, state=payload.state }
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
				if client_count >= constants.MAX_CLIENTS then
					send_error_packet(event.peer, "Game is full.")
				else
					local colour = table.remove(unused_colours)
					client_list[event.peer] =  {ip=msg_or_ip, port=port_or_nil, name=nil, time_since_last_msg = 0, colour = colour}
					client_count = client_count + 1
					print(event.peer:connect_id() .. ' connected.')
					send_join_accept(event.peer, colour)
				end
			elseif event.type == "disconnect" then
				if client_list[event.peer] ~= nil then
					remove_client(event.peer,  client_list[event.peer].name .." disconnected. Closed by user")
				end
			end
			event = host:service()
		end

		update_entity_positions(dt)
		if tick%constants.UPDATE_RATE == 0 then
			send_world_update()
			deleted = {}
		end
	end

	update_client_timeout(dt)
end

host:disconnect()
