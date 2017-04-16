Projectile = Class{ _includes = Entity,
    init = function(self, name, position, velocity, projectile_type, height, width, acceleration)
        Entity.init(self, name, position, velocity, "PROJECTILE", "DEFAULT")
        self.acceleration = acceleration
        self.projectile_type = projectile_type
        self.height = height
        self.width = width
        self.state_buffer = ProjectileStateBuffer(constants.PROJECTILE_BUFFER_LENGTH)
        self.spawn_data = { velocity = velocity:clone(), position = position:clone() }
    end;
    move = function(self, new)
        Entity.move(self, new)
    end;
    updateState = function(self, new_state)
        Entity.updateState(self, new_state)
    end;
    serverUpdate = function(self, update, update_tick)
        self.state_buffer:add(update, update_tick)
        --interpolate from server tick to now
        --self.velocity.x = round_to_nth_decimal(update.x_vel, 2)
    	--self.velocity.y = round_to_nth_decimal(update.y_vel, 2)
    end;
    update = function(self, dt)
        local last_server_update = self.state_buffer:get(self.state_buffer.current_max_tick)
        if last_server_update then
            local extrapolated_pos = nil
            print("extrapadoolin from " .. self.state_buffer.current_max_tick .. " to " .. tick)
            local extrapolation_tick_difference = tick - self.state_buffer.current_max_tick
            if extrapolation_tick_difference > 0 then
                local last_velocity = vector(last_server_update.projectile.x_vel,last_server_update.projectile.y_vel)
                extrapolated_pos = vector(last_server_update.projectile.x, last_server_update.projectile.y) + last_velocity * extrapolation_tick_difference * constants.TICKRATE
                extrapolated_pos = extrapolated_pos + self.velocity * dt
            end

            return vector(
                round_to_nth_decimal(extrapolated_pos.x,2),
                round_to_nth_decimal(extrapolated_pos.y,2)
            )
        end
    end;
}

Fireball = Class{ _includes = Projectile,
    init = function(self, name, position, velocity, height, width, acceleration)
        Projectile.init(self, name, position, velocity, "FIREBALL", height, width, acceleration)
        self.sprite_instance = get_sprite_instance("assets/sprites/fireball.lua")
        self.sprite_instance.rotation = velocity:angleTo(vector(0,-1))
        self.hitbox = HC.polygon(calculateProjectileHitbox(
        		position.x, position.y, velocity,
        		width, height))
        self.hitbox.owner = owner
        self.hitbox.type = "PROJECTILE"
        self.hitbox:rotate(math.pi/2, position.x, position.y)
    end;
    move = function(self, new)
        Projectile.move(self, new)
        local perpendicular = self.velocity:perpendicular():angleTo()
        local adjustedX = self.position.x + self.width/2*math.cos(perpendicular)
        local adjustedY = self.position.y + self.height/2*math.sin(perpendicular)
        self.hitbox:moveTo(adjustedX, adjustedY)
    end;
    serverUpdate = function(self, update, update_tick)
        Projectile.serverUpdate(self, update, update_tick)
    end;
    update = function(self, dt)
        local new_position = Projectile.update(self, dt)
        if new_position then
            self:move(new_position)
        end
    end;
}

--SHOULD MIRROR SERVER'S VERSION IN server/projectile.lua
function calculateProjectileHitbox(x1, y1, velocity, width, height)
    local angle = velocity:angleTo()
    local perpendicularAngle = velocity:perpendicular():angleTo()
	local x2 = x1 + (width * math.cos(angle))
	local y2 = y1 + (width * math.sin(angle))
	local x3 = x1 + (height * math.cos(perpendicularAngle)) --idk why +1.5 radians is the perpendicular but hey, it works
	local y3 = y1 + (height * math.sin(perpendicularAngle))
	local x4 = x3 + (x2 - x1) -- x3 + the difference between x1 and x2
	local y4 = y3 + (y2 - y1)

	return x1, y1, x2, y2, x4, y4, x3, y3 -- vertices in clockwise order
end
