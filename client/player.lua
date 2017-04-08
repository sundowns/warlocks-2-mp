player_colour = nil
player = {}

--[[ Class hierarchy
                      /-Fireball
         /-Projectile<
       /
Entity<         /-User
       \-Player<
                \-Enemy

]]

--Abstract class inherited by User and Enemy
Player = Class{ _includes = Entity,
    init = function(self, position, velocity, entity_type, name, colour, state, orientation,
    width, height)
        Entity.init(self, name, position, velocity, entity_type, state)
        self.colour = colour
        self.orientation = orientation
        self.width = width
        self.height = height
        self.hitbox = HC.circle(self.position.x,self.position.y,self.width/2)
        self.hitbox.owner = self.name
        self.hitbox.type = "PLAYER"
        --self.hasCollidedWith = {}
        self.sprite_instance = get_sprite_instance("assets/sprites/player-" .. self.colour ..".lua")
    end;
    centre = function(self)
        if self.orientation == "LEFT" then
            return self.position.x + self.width/2, self.position.y - self.height/2
        elseif self.orientation == "RIGHT" then
            return self.position.x - self.width/2, self.position.y - self.height/2
        end
    end;
    move = function(self, new)
        Entity.move(self, new)
        self.hitbox:moveTo(new.x, new.y)
    end;
    updateState = function(self, newState, isRetroactive)
        Entity.updateState(self, newState, isRetroactive)
    end;
}

Enemy = Class{ _includes = Player,
    init = function(self, position, name, colour, state, orientation, height, width, velocity)
        Player.init(self, position, velocity, "ENEMY", name, colour, state, orientation,
          height, width
        )
        --nothing else yet
    end;
    centre = function(self)
        return Player.centre(self)
    end;
    move = function(self, new)
        Player.move(self, new)
    end;
    updateState = function(self, newState)
        Player.updateState(self, newState)
    end;
    collidingWithPlayer = function(self, dt, collided_with, delta)
        if not collided_with or not delta or not dt then return end
        self.velocity = self.velocity +  delta * collided_with.velocity:len() * dt
        Player.move(self, self.position +  delta * self.hitbox._radius * dt)
    end;
}

User = Class{ _includes = Player,
    init = function(self, player_data)
        Player.init(self, vector(player_data.x, player_data.y),
         vector(player_data.x_vel, player_data.y_vel),
         player_data.entity_type, player_data.name, player_data.colour,
         player_data.state, player_data.orientation,
         player_data.width, player_data.height
        )
        self.max_movement_velocity = player_data.max_movement_velocity
        self.movement_friction = player_data.movement_friction
        self.base_acceleration = player_data.base_acceleration
        self.acceleration = player_data.acceleration
        self.dash = { -- TODO does this do anything????
            acceleration = tonumber(player_data.dash.acceleration),
            duration = tonumber(player_data.dash.duration), --for some reason bitser hates decimals in tables?
            timer = tonumber(player_data.dash.timer),
            cancellable_after = tonumber(player_data.dash.cancellable_after) --after timer is 0.7, so after 0.3seconds
        }
        self.spellbook = {}
        self.spellbook['SPELL1'] = "FIREBALL"
    end;
    centre = function(self)
        return Player.centre(self)
    end;
    move = function(self, new)
        Player.move(self, new)
    end;
    updateState = function(self, newState)
        Player.updateState(self, newState)
    end;
    beginDash = function(self, direction, isRetroactive)
        self.updateState(self, "DASH", isRetroactive)
        self.dash.timer = player.dash.duration
        self.dash.direction = direction
        self.acceleration = player.acceleration + player.dash.acceleration
    end;
    endDash = function(self)
    	self.dash.timer = self.dash.duration
    	self.updateState(self, "RUN")
    	self.acceleration = self.acceleration - self.dash.acceleration
    end;
    updateCooldowns = function(self, dt)
    	if self.state == "DASH" then
    		self.dash.timer = self.dash.timer - dt
    	end

    	if self.dash.timer < 0 then
    		self:endDash()
    	end
    end;
    collidingWithEnemy = function(self, dt, collided_with, delta)
        if not collided_with then return end
        self.velocity = self.velocity +  delta * collided_with.velocity:len() * dt
        self:move(self.position +  delta * self.hitbox._radius * dt)
        collided_with:collidingWithPlayer(dt, self, -1*delta)
    end;
    collidingWithObject = function(self, dt, delta)
        self:move(self.position +  delta * self.hitbox._radius * dt)
        self.velocity = self.velocity + delta * self.velocity:len2()/2 * dt
    end
}

function prepare_player(player_data)
	player = User(player_data)
	add_entity(player.name, player.entity_type, player)
	user_alive = true
end

function process_movement_input(player_obj, inputs, dt, isRetroactive)
    -- TODO: POLLING SYSTEM
    -- PLAN:
    -- have an input polling function seperate of normal game tick (possible????????) that puts inputs in a buffer as they come
    -- then on every tick, empty the buffer and calculate the average direction vector of the inputs.
    -- Normalise this (necessary?) and use as the input for that tick (and thus one to save in buffer)
    local resultant_input = vector(0,0)
	if player_obj.state == "STAND" or player_obj.state == "RUN" or player_obj.state == "DASH" then --or player.state == "TURN"
		local dash_multiplier = 1
		if player_obj.state == "DASH" then dash_multiplier = 1.5 end
		if inputs.right and not inputs.left then
            resultant_input.x = 1
			if (player_obj.velocity.x > -1*player_obj.dash.acceleration and player_obj.state == "STAND") then --or (player_obj.state == "DASH" and player_obj.orientation == "LEFT" and player.dash.timer < player.dash.cancellable_after)
				player_obj:beginDash("RIGHT", isRetroactive)
			end
		end
		if inputs.left and not inputs.right then
            resultant_input.x = -1
			if (player_obj.velocity.x < player_obj.dash.acceleration and player_obj.state == "STAND") then --or (player_obj.state == "DASH" and player_obj.orientation == "RIGHT" and player.dash.timer < player.dash.cancellable_after)
				player_obj:beginDash("LEFT", isRetroactive)
			end
		end
		if inputs.up and not inputs.down then
            resultant_input.y = -1
			if player_obj.velocity.y < player_obj.dash.acceleration and player_obj.state == "STAND" then
				player_obj:beginDash("UP", isRetroactive)
			end
		end
		if inputs.down and not inputs.up then
            resultant_input.y = 1
			if player_obj.velocity.y > -1*player_obj.dash.acceleration and player_obj.state == "STAND" then
				player_obj:beginDash("DOWN", isRetroactive)
			end
		end

        resultant_input:normalizeInplace()
        player_obj.velocity = player_obj.velocity + resultant_input * player_obj.acceleration * dash_multiplier * dt

        if player_obj.velocity:len() > player_obj.max_movement_velocity then
            player_obj.velocity = player_obj.velocity:normalized() * player_obj.max_movement_velocity
        end
	end

	return player_obj
end

function update_player_movement(player_obj, inputs, dt, isRetroactive)
	local friction = constants['PLAYER_FRICTION']
	if (not inputs.up and not inputs.down and
	not inputs.left and not inputs.right) then
		friction = friction*2
	end

    if inputs.left and not inputs.right then player_obj.orientation = "LEFT" end
    if inputs.right and not inputs.left then player_obj.orientation = "RIGHT" end

	player_obj = update_entity_movement(dt, player_obj, friction, true, isRetroactive)
	return player_obj
end

function get_input_snapshot()
	return {
		up = love.keyboard.isDown((settings.controls["UP"])),
		right = love.keyboard.isDown((settings.controls["RIGHT"])),
		left = love.keyboard.isDown((settings.controls["LEFT"])),
		down = love.keyboard.isDown((settings.controls["DOWN"])),
        spell1 = love.keyboard.isDown((settings.controls["SPELL1"])),
        spell2 = love.keyboard.isDown((settings.controls["SPELL2"])),
        spell3 = love.keyboard.isDown((settings.controls["SPELL3"])),
        spell4 = love.keyboard.isDown((settings.controls["SPELL4"])),
        spell5 = love.keyboard.isDown((settings.controls["SPELL5"]))
	}
end

function create_player_state_snapshot(x, y, x_vel, y_vel, state, acceleration,
	orientation, dash, max_movement_velocity)
	return {
        position = vector(x, y),
		x_vel = x_vel,
		y_vel = y_vel,
        velocity = vector(x_vel, y_vel),
		state = state,
		acceleration = acceleration,
		orientation = orientation,
		dash = dash,
		max_movement_velocity = max_movement_velocity
	}
end

function get_player_state_snapshot()
	return {
		position = player.position,
		x_vel = player.x_vel,
		y_vel = player.y_vel,
        velocity = player.velocity,
		state = player.state,
		acceleration = player.acceleration,
		orientation = player.orientation,
		dash = player.dash,
		max_movement_velocity = player.max_movement_velocity
	}
end

function retroactive_player_state_calc(update)
	local old = player_state_buffer:get(tonumber(update.server_tick))
	local updated_state = create_player_state_snapshot(update.x, update.y, update.x_vel, update.y_vel, update.state,
	old.player.acceleration, old.player.orientation, old.player.dash, old.player.max_movement_velocity)
	old.player = updated_state

    player_state_buffer:replaceAndRemoveOld(tonumber(update.server_tick), old)

    local result_state = updated_state
	local updated = false
    --TODO: SHOULD WE BE DOING THIS 2 AT A TIME?????
	for index=update.server_tick, tick-last_offset,2 do --Lets make sure we're not correcting events as they happen.
        local snapshot = player_state_buffer:get(index)
        assert(snapshot)
        local input = snapshot.input
		result_state = calc_new_player_state(result_state, input, constants.TICKRATE*2) --(dt = 2 ticks)
        player_state_buffer:replace(index, {player=result_state,input=input,tick=index})
		updated = true
	end

	--update player with result state
	if updated then
		apply_player_updates(result_state)
		print("applying results of retroactive update")
	end
end

function calc_new_player_state(previous_state, input, dt)
	--Apply input & dt to old state to calc new state.
	local resultant = process_movement_input(previous_state, input, dt, true)
	resultant = update_player_movement(resultant, input, dt, true)
	return resultant
end


function apply_player_updates(result)
    player:move(vector(result.x, result.y))
	--player.position = vector(result.x, result.y)
    player.velocity = vector(result.x_vel, result.y_vel)
	player:updateState(result.state)
end
