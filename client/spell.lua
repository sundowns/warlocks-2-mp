Projectile = Class{ _includes = Entity,
    init = function(self, name, position, velocity, projectile_type, height, width)
        Entity.init(self, name, position, velocity, "PROJECTILE", "DEFAULT")
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
    init = function(self, name, position, velocity, height, width)
        Projectile.init(self, name, position, velocity, "FIREBALL", height, width)
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
        
        self.hitbox:moveTo(new.x, new.y)
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
