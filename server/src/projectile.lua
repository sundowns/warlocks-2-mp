Projectile = Class{ _includes = Entity,
    init = function(self, id, position, owner, speed, velocity, width, height, damage,
        impact_force
    )
        Entity.init(self, id, position, "PROJECTILE")
        self.width = width
        self.height = height
        self.owner = owner
        self.speed = speed
        self.velocity = velocity
        self.damage = damage
        self.impact_force = impact_force
    end;
    asSpawnPacket = function(self)
        local packet = Entity.asSpawnPacket(self)
        packet.x_vel = tostring(self.velocity.x)
        packet.y_vel = tostring(self.velocity.y)
        packet.owner = self.owner
        packet.entity_type = self.entity_type
        packet.speed = self.speed
        return packet
    end;
    asUpdatePacket = function(self)
        local packet = Entity.asUpdatePacket(self)
        packet.x_vel = tostring(round_to_nth_decimal(self.velocity.x,2))
        packet.y_vel = tostring(round_to_nth_decimal(self.velocity.y,2))
        packet.entity_type = self.entity_type
        packet.speed = self.speed
        return packet
    end;
}

FireballProjectile = Class{ _includes = Projectile,
    init = function(self, id, position, owner, speed, direction, width, height, impact_force)
        local perpendicular = direction:perpendicular():angleTo()
        local adjustedX = position.x - width/2*math.cos(perpendicular)
        local adjustedY = position.y - height/2*math.sin(perpendicular)
        local velocity = direction*speed
        Projectile.init(self, id, vector(adjustedX, adjustedY), owner, speed,
            velocity, width, height, constants.DEFAULTS.FIREBALL.damage, impact_force
        )
        self.projectile_type = "FIREBALL"
        self.hitbox = HC.polygon(calculateProjectileHitbox(
        		adjustedX, adjustedY, velocity,
        		width, height))
        self.hitbox.owner = owner
        self.hitbox.id = id
        self.hitbox.type = "PROJECTILE"
        self.hitbox:rotate(math.pi/2, adjustedX, adjustedY)
        self.hitbox.collided_with = {}
        self.explosion_radius = 15
        self.explosion_ttl = 0.7
    end;
    asSpawnPacket = function(self)
        local packet = Projectile.asSpawnPacket(self)
        packet.projectile_type = self.projectile_type
        return packet
    end;
    asUpdatePacket = function(self)
        return Projectile.asUpdatePacket(self)
    end;
    hitObject = function(self, id, delta, obj_position)
        self.hitbox.collided_with[id] = true
        local cX, cY = self.hitbox:center()
        local midX, midY = calc_mid_point(cX, cY, obj_position.x, obj_position.y) -- need a different solution for static objects (use delta?)
        spawn_explosion(midX, midY, self.explosion_radius, self.hitbox.owner, self.explosion_ttl)
    end;
}

function spawn_projectile(x, y, velocity_vector, owner, impact_force)
    local id = random_string(12)
    new_projectile = FireballProjectile(id, vector(x,y), owner, constants.DEFAULTS.FIREBALL.speed, velocity_vector:normalized(), 14, 19,
        impact_force
    )

    while world["entities"][id] ~= nil do
        id = id .. 'a'
    end
    world["entities"][id] = new_projectile
    --TODO: Start player cooldown (and check the skill is ready in the first place)

    broadcast_cast_spell_packet(new_projectile, id)

    Timer.after(5, function()
        remove_entity(id)
    end)
end

-- SHOULD MIRROR CLIENT'S VERSION IN client/spell.lua
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
