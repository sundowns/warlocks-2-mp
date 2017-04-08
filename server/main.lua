package.path = '.\\?.lua;'.. '.\\libs\\?.lua;' .. '.\\libs\\?\\init.lua;' .. package.path
package.cpath = '.\\libs\\?.dll;' .. package.cpath

require "socket" -- to keep track of time
binser = require "binser"
constants = require("constants")
enet = require "enet"
host = enet.host_create("*:12345")
vector = require "vector"
Timer = require "timer"
HC = require "HC"
config = require "config"
Class = require "class"
md5 = require "md5"
--host:bandwidth_limit(1024000, 1024000)

server_version = "0.0.1"
require("util")
require("network")
require("entity")
require("world")
require("projectile")
require("player")

local running = true
local t = 0
local prevTime = socket.gettime()
tick = 0
local tick_timer = 0
unused_colours = {"purple","green","red", "blue", "orange"}

log("Initialising world...")
load_stage()
--HC.resetHash([cell_size = 100]) --reset/set HC world cell size

log("Beginning server loop.")
while running do
	time = socket.gettime()
	local dt = time - prevTime
	prevTime = time
	tick_timer = tick_timer + dt
    Timer.update(dt)

	if tick_timer > constants.TICKRATE then
		tick = tick + 1
		tick_timer = tick_timer - constants.TICKRATE
		local event = host:service()
		while event ~= nil do
			if event.type == "receive" then
				if not xpcall(binser.deserialize, event.data) then
					payload = binser.deserialize(event.data)
					setmetatable(payload, packet_meta)
					if not assert(payload.alias) then log(tostring(payload)) end
					assert(client_list[event.peer:index()])
					if client_list[event.peer:index()] ~= nil then
						client_list[event.peer:index()].time_since_last_msg = 0
					end
					assert(payload.cmd)
					if payload.cmd == "PLAYERUPDATE" then
						if client_list[event.peer:index()] then
							assert(payload.client_tick)
							assert(payload.x_vel and payload.y_vel and payload.x and payload.y and payload.state)
							local ent = world["players"][payload.alias]
							if ent then

								--TODO: VERIFY STATE CHANGE

								if verify_position_update(ent, payload) and verify_velocity_update(ent, payload) then
                                    apply_player_position_update(ent, payload)
                                    apply_player_velocity_update(ent, payload)
								else
                                    send_client_correction_packet(event.peer, payload.alias, false)
									log("[ANTI-CHEAT] Rejected player update from " .. payload.alias)
								end
							else
								log("[WARNING] tried to UPDATE non existing player. " .. payload.alias)
							end
						end
					elseif payload.cmd == 'JOIN' then
						if tostring(payload.client_version) ~= server_version then
							send_error_packet(event.peer, "Incorrect version. Server is running " .. server_version)
							remove_client(event.peer, "Client version " .. payload.client_version .. " conflicts with server version " .. server_version)
                        else
                            if tostring(payload.hash) ~= STAGE_HASH then
                                print("client hash: " .. tostring(payload.hash) .. " did not match server: " .. STAGE_HASH)
                                --TODO: Figure out how to get a consistent hash between server & client (server hash changes every time???)
                                --send_error_packet(event.peer, "Stage file failed checksum. \nPlease ensure you have the correct version of stage " .. config.STAGE)
    							--remove_client(event.peer, "Dropped " .. payload.alias .. ". Stage file does not match servers version")
                            end
							client_list[event.peer:index()].name = payload.alias

							if world["players"][payload.alias] then
								send_error_packet(event.peer, "The alias " .. payload.alias .. " is already in use.")
								remove_client(payload.alias, "Duplicate alias")
							else
								client_player_map[event.peer:index()] = payload.alias
								send_player_spawn_packet(event.peer, spawn_player(payload.alias, 250, 250, event.peer:index()))
							end
						end
					elseif payload.cmd == 'UPDATE' then
						log('[WARNING] Explicitly requested world update received. Potential security risk.')
                    elseif payload.cmd == 'CASTSPELL' then
                        assert(payload.spell_type)
                        if world["players"][payload.alias] then
                            world["players"][payload.alias]:castSpell(payload.spell_type, payload.at_X, payload.at_Y)
                        else
                            log("[WARNING] Non-existant player: " .. payload.alias .. " attempted to cast fierball")
                        end
                    elseif payload.cmd == 'STAGEINFO' then
                        assert(payload.hash)
                        if STAGE_HASH ~= payload.hash then
                            print("send error to user") -- TODO
                        end
                    else
						log("[WARNING] unrecognised command: " .. payload.cmd)
					end
				else
					log("Failed to packet: " .. tostring(event.data))
				end
			elseif event.type == "connect" then
				if client_count >= constants.MAX_CLIENTS then
					send_error_packet(event.peer, "Game is full.")
				else
					local colour = table.remove(unused_colours)
					client_list[event.peer:index()] =  {ip=msg_or_ip, port=port_or_nil, name='', time_since_last_msg = 0, colour = colour}
					client_count = client_count + 1
					log(event.peer:connect_id() .. ' connected.')
					send_join_accept(event.peer, colour)
				end
			elseif event.type == "disconnect" then
				if client_list[event.peer:index()] ~= nil then
					remove_client(event.peer,  client_list[event.peer:index()].name .." disconnected. Closed by user")
				end
			end
			event = host:service()
		end

        --disabled for now (forever? just verify off the back of client-detected collisions instead? 100x easier)
        process_collisions(dt)
        update_entity_positions(dt)
		if tick%constants.NET_PARAMS.NET_UPDATE_RATE == 0 then
			send_world_update()
			deleted = {}
		end

        update_client_timeout(dt)
	end
    send_buffered_corrections()
end

host:disconnect()
