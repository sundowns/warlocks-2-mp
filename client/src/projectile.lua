Projectile = Class{ _includes = Entity,
    init = function(self, name, position, velocity, projectile_type, height, width, speed)
        Entity.init(self, name, position, velocity, "PROJECTILE", "DEFAULT")
        self.speed = speed
        self.projectile_type = projectile_type
        self.height = height
        self.width = width
        --self.state_buffer = ProjectileStateBuffer(constants.PROJECTILE_BUFFER_LENGTH)
        self.spawn_data = { velocity = velocity:clone(), position = position:clone() }
    end;
    move = function(self, new)
        Entity.move(self, new)
    end;
    updateState = function(self, new_state)
        Entity.updateState(self, new_state)
    end;
    serverUpdate = function(self, update, update_tick)
        --shouldnt be touched atm (only do it when things ACTUALLY CHANGE FROM WHAT WE EXPECT)
        --self.state_buffer:add(update, update_tick)
    end;
    update = function(self, dt)
        --nah
    end;
}

FireballProjectile = Class{ _includes = Projectile,
    init = function(self, name, position, velocity, owner, height, width, speed)
        Projectile.init(self, name, position, velocity, "FIREBALL", height, width, speed)
        self.sprite_instance = get_sprite_instance("assets/sprites/fireball.lua")
        self.sprite_instance.rotation = velocity:angleTo(vector(0,-1))
        self.hitbox = HC.polygon(calculateProjectileHitbox(
        		position.x, position.y, velocity,
        		width, height))
        self.hitbox.owner = owner
        self.hitbox.id = name
        self.hitbox.type = "PROJECTILE"
        self.hitbox:rotate(math.pi/2, position.x, position.y)
    end;
    move = function(self, delta)
        Projectile.move(self, self.position + delta)
        self.hitbox:move(delta.x, delta.y)
    end;
    centre = function(self)
        local perpendicular = self.velocity:perpendicular():angleTo()
        local adjustedX = self.position.x + self.width/2*math.cos(perpendicular)
        local adjustedY = self.position.y + self.width/2*math.sin(perpendicular)
        return adjustedX, adjustedY
    end;
    serverUpdate = function(self, update, update_tick)
        Projectile.serverUpdate(self, update, update_tick)
    end;
    update = function(self, dt)
        self:move(self.velocity*dt)
    end;
    draw = function(self)
        draw_instance(self.sprite_instance, self.position.x, self.position.y)
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
