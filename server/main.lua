package.path = '.\\?.lua;'.. '.\\libs\\?.lua;' .. '.\\libs\\?\\init.lua;' .. package.path
package.cpath = '.\\libs\\?.dll;' .. package.cpath

require "socket" -- to keep track of time
binser = require 'binser'
constants = require("constants")
enet = require "enet"
host = enet.host_create("*:12345")
vector = require "vector"
Timer = require "timer"
HC = require "HC"
config = require "config"
--host:bandwidth_limit(1024000, 1024000)

server_version = "0.0.1"
require("util")
require("network")
require("world")
require("player")

local running = true
local t = 0
local prevTime = socket.gettime()
tick = 0
local tick_timer = 0
unused_colours = {"purple","green","red", "blue", "orange"}

print("Initialising world...")
load_stage()


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
				if not xpcall(binser.deserialize, event.data) then
					payload = binser.deserialize(event.data)
					setmetatable(payload, packet_meta)
					if not assert(payload.alias) then print(tostring(payload)) end
					assert(client_list[event.peer])
					if client_list[event.peer] ~= nil then
						client_list[event.peer].time_since_last_msg = 0
					end
					assert(payload.cmd)
					if payload.cmd == "PLAYERUPDATE" then
						if client_list[event.peer] then
							assert(payload.client_tick)
							assert(payload.x_vel and payload.y_vel and payload.x and payload.y and payload.state)
							local ent = world["players"][payload.alias]
							if ent then

								--TODO: VERIFY STATE CHANGE

								if verify_position_update(ent, payload) then
                                    apply_player_position_update(ent, payload)
                                    -- world["players"][payload.alias] = {
                                    --     velocity = vector(round_to_nth_decimal(payload.x_vel, 2), round_to_nth_decimal(payload.y_vel,2)),
                                    --     x=round_to_nth_decimal(payload.x,2),
                                    --     y=round_to_nth_decimal(payload.y,2),
                                    --     state = payload.state, orientation = payload.orientation
                                    -- }
								else
                                    send_client_correction_packet(event.peer, payload.alias)
									print("[ANTI-CHEAT] Rejected player update from " .. payload.alias)
								end
							else
								print("[WARNING] tried to UPDATE non existing player. " .. payload.alias)
							end
						end
					elseif payload.cmd == 'JOIN' then
						if tostring(payload.client_version) ~= server_version then
							send_error_packet(event.peer, "Incorrect version. Server is running " .. server_version)
							remove_client(event.peer, event.peer .. " version " .. payload.client_version .. " conflicts with server version " .. server_version)
						else
							client_list[event.peer].name = payload.alias
							if world["players"][payload.alias] then
								send_error_packet(event.peer, "The alias " .. payload.alias .. " is already in use.")
								remove_client(payload.alias, "Duplicate alias")
							else
								client_player_map[event.peer] = payload.alias
								send_spawn_packet(event.peer, spawn_player(payload.alias, 250, 250, client_list[event.peer].colour))
							end
						end
					elseif payload.cmd == 'UPDATE' then
						print('[WARNING] Explicitly requested world update received. Potential security risk.')
                    elseif payload.cmd == 'CASTSPELL' then
                        assert(payload.spell_type)
                        if payload.spell_type == "FIREBALL" then
                            --verify cast packet
                            if world["players"][payload.alias] then
                                player_cast_fireball(payload.player_x, payload.player_y, payload.at_X, payload.at_Y, payload.alias)
                            else
                                print("[WARNING] Non-existant player: " .. payload.alias .. " attempted to cast fierball")
                            end
                        end
					else
						print("[WARNING] unrecognised command: " .. payload.cmd)
					end
				else
					print("Failed to packet: " .. tostring(event.data))
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
		if tick%constants.NET_PARAMS.NET_UPDATE_RATE == 0 then
			send_world_update()
			deleted = {}
		end

        update_client_timeout(dt)
        --process_collisions(dt)
	end
end

host:disconnect()
