Projectile = Class{ _includes = Entity,
    init = function(self, name, position, velocity, projectile_type, height, width, acceleration)
        Entity.init(self, name, position, velocity, "PROJECTILE", "DEFAULT")
        self.acceleration = acceleration
        self.projectile_type = projectile_type
        self.height = height
        self.width = width
    end;
    move = function(self, new)
        Entity.move(self, new)
    end;
    updateState = function(self, newState)
        Entity.updateState(self, newState)
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
        --[[TODO: This is currently just kind of estimating,
            it needs to use a state buffer and calculate where it should be based on server tick it spawned
            + ticks since. Should be able to do 100% because its constant speed!
        --]]
        Projectile.move(self, new)
        local perpendicular = self.velocity:perpendicular():angleTo()
        local adjustedX = self.position.x + self.width/2*math.cos(perpendicular)
        local adjustedY = self.position.y + self.height/2*math.sin(perpendicular)
        local delta = self.velocity:normalized() * self.acceleration * (constants.TICKRATE / 3.85) -- server net update rate!!
        self.hitbox:move(delta.x, delta.y)
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
