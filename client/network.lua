local enet = require "enet"
local server
local host
last_rtt = 0
last_offset = 1
connected = false
connection_is_new = true
connected_time = 0
debug_log = {}
--TODO: Create & use a new one for projectile/entity states to extrapolate position based on server updates
--base class (NOTHING SPECIFIC TO ANY ENTITY!)
StateBuffer = Class{
    init = function(self, size)
        self.max_size = size
        self.current_max_tick = 0
        self.largest_index = 0
        self.buffer = {}
    end;
    add = function(self, info_tick, snapshot)
        self.largest_index = table.insert(self.buffer, snapshot)
        self.current_max_tick = info_tick
        if #self.buffer > self.max_size then
            table.remove(self.buffer, 1)
        end
    end;
    getIndexByTick = function(self, in_tick)
        if StateBuffer.getMinimumTick(self) > in_tick then
            return nil --this tick's state isnt in the buffers current range
        end
        --DONT DELETE THE FOLLOWING COMMENTED OUT DBG LINE.
        --It demonstrates fundamental networking problem at the moment
        --The client seems to stutter/skip ticks (as it processes other stuff?? OR as it falls behind the sever & gets synced up?)
        --dbg("max: " .. self.current_max_tick .. " - " .. in_tick .. " = " .. (self.current_max_tick - in_tick) )
        return table.maxn(self.buffer) - (self.current_max_tick - in_tick)
    end;
    replaceAndRemoveOld = function(self, in_tick, snapshot)
        local index_to_replace = StateBuffer.replace(self, in_tick, snapshot)

        --remove the older ones here too
        for i = 1, index_to_replace - 1, 1 do
            table.remove(self.buffer, i)
        end
    end;
    replace = function(self, in_tick, snapshot)
        local index_to_replace = StateBuffer.getIndexByTick(self,in_tick)
        if not index_to_replace then return false end
        self.buffer[index_to_replace] = snapshot
        return index_to_replace
    end;
    getCurrentSize = function(self)
        return #self.buffer
    end;
    getMinimumTick = function(self)
        return self.current_max_tick - #self.buffer
    end;
    get = function(self, in_tick)
        if self.current_max_tick == 0 then return nil end
        local snapshot_index = StateBuffer.getIndexByTick(self,tonumber(in_tick))
        if not snapshot_index then return nil end
        local snapshot = self.buffer[snapshot_index]
        if not snapshot then return nil end
        if snapshot.tick ~= in_tick then
            warning("[WARNING] snapshot tick [".. snapshot.tick ..
                 "] did not match parameter tick [" .. in_tick .. "]")
        end
        -- assert(snapshot.tick == in_tick, "snapshot tick [".. snapshot.tick ..
        --     "] did not match parameter tick [" .. in_tick .. "]")

        return snapshot
    end;
}

ProjectileStateBuffer = Class{_includes=StateBuffer,
    init = function(self, size)
        StateBuffer.init(self, size)
    end;
    get = function(self, in_tick)
        return StateBuffer.get(self, in_tick)
    end;
    add = function(self, state, server_tick)
        local state_snapshot = {projectile = state, tick = server_tick}
        StateBuffer.add(self, server_tick, state_snapshot)
    end;
    printDump = function(self, force)
        print_table(self.buffer, force, "[Projectile State Buffer Dump]")
    end;
}

--for player (INCLUDES INPUTS)
PlayerStateBuffer = Class{ _includes=StateBuffer,
    init = function(self, size)
        StateBuffer.init(self, size)
    end;
    get = function(self, in_tick)
        return StateBuffer.get(self, in_tick)
    end;
    add = function(self, state, input, client_tick)
        local state_snapshot = {player = state, input = input, tick = client_tick}
        StateBuffer.add(self, client_tick, state_snapshot)
    end;
    printDump = function(self, force)
        print_table(self.buffer, force, "[Player State Buffer Dump]")
    end;
}

function net_initialise()
	host = enet.host_create()
	server = host:connect(settings.IP..':'..settings.port)
    print("connecting to " .. settings.IP .. ":" .. settings.port .."...")
end

function listen(timeout)
	if timeout == nil then timeout = 0 end
	return host:service(timeout)
end

function sync_client(server_tick)
	if connection_is_new then
		last_rtt = constants.NET_PARAMS.STABILISATION_RTT
	else
		last_rtt = server:last_round_trip_time()
	end
	offset = math.min(math.floor(last_rtt/1000/constants.TICKRATE+1), 2)
	tick = server_tick + offset -- server tick + ticks per RTT + 1
	last_offset = offset
end

function confirm_join(server_stage, assigned_colour)
    --check if stage exists, if not then download the stage or error
    --otherwise (or after the file download), send join accept packet
    local hash = load_stage(server_stage..".lua")
    player_colour = assigned_colour
	server:round_trip_time(10)
	tick = payload.server_tick
	server:send(create_binary_packet({client_version = constants.CLIENT_VERSION, hash = hash}, "JOIN", tick, settings.username))
	connected = true
    GamestateManager.switch(game)
end

function disconnect(msg)
	if msg then print(msg) end
	server:disconnect()
	host:flush()
	connected = false
	GamestateManager.switch(error_screen, msg)
end

function send_player_update(inPlayer, inName)
	if not connected then return end
	local playerVM = {
		x = inPlayer.position.x,
		y = inPlayer.position.y,
		state = inPlayer.state,
		acceleration = inPlayer.acceleration,
		x_vel = inPlayer.velocity.x,
		y_vel = inPlayer.velocity.y,
        orientation = inPlayer.orientation
	}
	server:send(create_binary_packet(playerVM, "PLAYERUPDATE", tick, inName))
end

function send_action_packet(action, data)
    if not connected then return end
    server:send(create_binary_packet(data, action, tick, settings.username))
end

function display_net_info()
	love.graphics.setColor(0, 255, 100)
	set_font(12, 'debug')
	if connected then
		love.graphics.print("rtt: "..last_rtt, camera:worldCoords(3,0))
		if connection_is_new then
			love.graphics.print("stabilising...", camera:worldCoords(70,0))
		end
	else
		love.graphics.print("Disconnected.", camera:worldCoords(3,0))
	end
	reset_colour()
end

function update_connection(dt)
	if connected then
		connected_time = connected_time + dt
		if connection_is_new and connected_time > constants.NET_PARAMS.STABILISATION_TIME then
			connection_is_new = false
		end
	end
end

packet_meta = {}
function packet_meta.__index(table, key)
    if key == 'alias' then
        return table[4]
    elseif key == 'cmd'then
        return table[3]
    elseif key == 'server_tick' or key == 'tick' then
       return table[2]
    else
        return table[1][key]
    end
end

function create_binary_packet(payload, cmd, tick, alias)
	return binser.serialize(payload, tostring(tick), cmd, alias)
end

function verify_player_correction_packet(payload)
    local update = {
        x = tonumber(payload.x),
        y = tonumber(payload.y),
        x_vel = tonumber(payload.x_vel),
        y_vel = tonumber(payload.y_vel),
        state = payload.state,
        colour = payload.colour,
        entity_type = "PLAYER",
        server_tick = payload.server_tick
    }
    local verified = true
    if not assert(update.x) then verified = false print("Failed to verify x update for player") end
    if not assert(update.y) then verified = false print("Failed to verify y update for player") end
    if not assert(update.x_vel) then verified = false print("Failed to verify x_vel update for player") end
    if not assert(update.y_vel) then verified = false print("Failed to verify y_vel update for player") end
    if not assert(update.state) or not type(update.state) == 'string' then verified = false print("Failed to verify state update for player") end
    if not assert(update.colour) or not type(update.colour) == 'string' then verified = false print("Failed to verify colour update for player") end
    if not assert(update.server_tick) then verified = false print("Failed to verify tick") end
    return verified, update
end

function verify_spawn_player_packet(payload)
    local update = {
        x = tonumber(payload.x),
        y = tonumber(payload.y),
        x_vel = tonumber(payload.x_vel),
        y_vel = tonumber(payload.y_vel),
        entity_type = payload.entity_type,
        state = payload.state,
        dash = payload.dash,
        colour = payload.colour,
        orientation = payload.orientation,
        name = payload.name,
        width = tonumber(payload.width),
        height = tonumber(payload.height),
        max_movement_velocity = tonumber(payload.max_movement_velocity),
        acceleration = tonumber(payload.acceleration),
        movement_friction = tonumber(payload.movement_friction),
        base_acceleration = tonumber(payload.base_acceleration)
    }

    local verified = true
    if not assert(update.x) then verified = false print("Failed to verify x for player spawn packet") end
    if not assert(update.y) then verified = false print("Failed to verify y for player spawn packet") end
    if not assert(update.x_vel) then verified = false print("Failed to verify x_vel for player spawn packet") end
    if not assert(update.y_vel) then verified = false print("Failed to verify y_vel for player spawn packet") end
    if not assert(update.entity_type  == 'PLAYER') or not type(update.entity_type) == 'string' then verified = false print("Failed to verify entity_type for player spawn packet") end
    if not assert(update.state) or not type(update.state) == 'string' then verified = false print("Failed to verify state for player spawn packet") end
    if not assert(update.colour) or not type(update.colour) == 'string' then verified = false print("Failed to verify colour for player spawn packet") end
    if not assert(update.orientation) or not type(update.orientation) == 'string' then verified = false print("Failed to verify orientation for player spawn packet") end
    if not assert(update.name) or not type(update.name) == 'string' then verified = false print("Failed to verify name for player spawn packet") end
    if not assert(update.width) then verified = false print("Failed to verify width for player spawn packet") end
    if not assert(update.height) then verified = false print("Failed to verify height for player spawn packet") end
    if not assert(update.dash) or not type(update.name) == 'table' then verified = false print("Failed to verify dash for player spawn packet") end
    if not assert(update.max_movement_velocity) then verified = false print("Failed to verify max_movement_velocity for player spawn packet") end
    if not assert(update.acceleration) then verified = false print("Failed to verify acceleration for player spawn packet") end
    if not assert(update.movement_friction) then verified = false print("Failed to verify movement_friction for player spawn packet") end
    if not assert(update.base_acceleration) then verified = false print("Failed to verify base_acceleration for player spawn packet") end
    return verified, update
end

function verify_spawn_projectile_packet(payload)
    local update = {
        x = tonumber(payload.x),
        y = tonumber(payload.y),
        x_vel = tonumber(payload.x_vel),
        y_vel = tonumber(payload.y_vel),
        entity_type = payload.entity_type,
        alias = payload.alias,
        width = tonumber(payload.width),
        height = tonumber(payload.height),
        projectile_type = payload.projectile_type,
        speed = payload.speed
    }

    local verified = true
    if not assert(update.x) then verified = false print("Failed to verify x for projectile spawn packet") end
    if not assert(update.y) then verified = false print("Failed to verify y for projectile spawn packet") end
    if not assert(update.x_vel) then verified = false print("Failed to verify x_vel for projectile spawn packet") end
    if not assert(update.y_vel) then verified = false print("Failed to verify y_vel for projectile spawn packet") end
    if not assert(update.entity_type  == 'PROJECTILE') or not type(update.entity_type) == 'string' then verified = false print("Failed to verify entity_type for projectile spawn packet") end
    if not assert(update.alias) or not type(update.alias) == 'string' then verified = false print("Failed to verify alias for projectile spawn packet") end
    if not assert(update.width) then verified = false print("Failed to verify width for projectile spawn packet") end
    if not assert(update.height) then verified = false print("Failed to verify height for projectile spawn packet") end
    if not assert(update.speed) then verified = false print("Failed to verify speed for projectile spawn packet") end
    if not assert(update.projectile_type) then verified = false print("Failed to verify projectile_type for projectile spawn packet") end
    return verified, update
end

function verify_spawn_explosion_packet(payload)
    local update = {
        id = payload.alias,
        x = tonumber(payload.x),
        y = tonumber(payload.y),
        entity_type = payload.entity_type,
        radius = payload.radius
    }

    local verified = true
    if not assert(update.x) then verified = false print("Failed to verify x for explosion spawn packet") end
    if not assert(update.y) then verified = false print("Failed to verify y for explosion spawn packet") end
    if not assert(update.entity_type  == 'EXPLOSION') or not type(update.entity_type) == 'string' then verified = false print("Failed to verify entity_type for explosion spawn packet") end
    if not assert(update.id) or not type(update.id) == 'string' then verified = false print("Failed to verify id for explosion spawn packet") end
    if not assert(update.radius) then verified = false print("Failed to verify radius for explosion spawn packet") end
    return verified, update
end

function network_run()
    if connected then
        network_gamerunning()
    else
        network_loading()
    end
end

function network_loading()
    repeat
        event = listen()
        if event and event.type == "receive" then
            payload = binser.deserialize(event.data)
            setmetatable(payload, packet_meta)
            if payload.cmd == 'SERVERERROR' then
                disconnect("Connection closed. \n" ..payload.message)
            elseif payload.cmd == 'JOINACCEPTED' then
                sync_client(payload.server_tick)
                confirm_join(payload.stage_name, payload.colour)
            end
        elseif event and event.type == "connect" then
            dbg("[WARNING] connect message received")
        elseif event and event.type == "disconnect" then
            disconnect("Server closed")
        end
    until not event
end

function network_gamerunning()
    if tick%constants.NET_PARAMS.NET_UPDATE_RATE == 0 then
        if user_alive then
            send_player_update(player, settings.username)
        end

        repeat
            event = listen()
            if event and event.type == "receive" then
                payload = binser.deserialize(event.data)
                setmetatable(payload, packet_meta)
                if payload.cmd == "ENTITYUPDATE" then
                    assert(payload.alias)
                    assert(payload.server_tick)
                    sync_client(payload.server_tick)
                    if world[payload.alias] == nil and payload.entity_type == "PLAYER" then
                        add_entity(payload.alias, payload.entity_type, payload)
                    else
                        if payload.alias ~= settings.username then
                            server_entity_update(payload.alias, payload)
                        else
                            server_player_update(payload)
                        end
                    end
                elseif payload.cmd == 'ENTITYDESTROY' then
                    remove_entity(payload.alias, payload.entity_type)
                elseif payload.cmd == 'SPAWN_PLAYER' then
                    local ok, update = verify_spawn_player_packet(payload)
                    if ok then
                        prepare_player(update)
                    end
                elseif payload.cmd == 'SPAWN_PROJECTILE' then
                    local ok, data = verify_spawn_projectile_packet(payload)
                    if ok then
                        server_entity_create(data)
                    end
                elseif payload.cmd == 'SPAWN_EXPLOSION' then
                    local ok, data = verify_spawn_explosion_packet(payload)
                    if ok then
                        server_entity_create(data)
                    end
                elseif payload.cmd == 'PLAYERCORRECTION' then
                    local ok, update = verify_player_correction_packet(payload)
                    if ok then
                        if payload.retroactive == true then
                            server_player_update(update, true) --runs retroactive update process
                        else
                            apply_player_updates(update) -- simply applies the updates AS IS (no winding back ticks and recalculating)
                        end
                    end
                elseif payload.cmd == 'SERVERERROR' then
                    disconnect("Connection closed. " ..payload.message)
                elseif payload.cmd == 'DEBUG' then
                    debug_log[#debug_log+1] = payload.message

                    testX1 = tonumber(payload.x1)
                    testX2 = tonumber(payload.x2)
                    testX3 = tonumber(payload.x3)
                    testX4 = tonumber(payload.x4)
                    testY1 = tonumber(payload.y1)
                    testY2 = tonumber(payload.y2)
                    testY3 = tonumber(payload.y3)
                    testY4 = tonumber(payload.y4)
                    testEntX = tonumber(payload.entX)
                    testEntY = tonumber(payload.entY)
                else
                    dbg("unrecognised command:", payload.cmd)
                end
            elseif event and event.type == "connect" then
                dbg("connect msg received")
            elseif event and event.type == "disconnect" then
                disconnect("Server closed")
            end
        until not event
    end
end
