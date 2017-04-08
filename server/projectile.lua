Projectile = Class{ _includes = Entity,
    init = function(self, position, owner, acceleration, velocity, width, height)
        Entity.init(self, position, width, height)
        self.owner = owner
        self.entity_type = "PROJECTILE"
        self.acceleration = acceleration
        self.velocity = velocity
    end;
    asSpawnPacket = function(self)
        local packet = Entity.asSpawnPacket(self)
        packet.x_vel = tostring(self.velocity.x)
        packet.y_vel = tostring(self.velocity.y)
        packet.owner = self.owner
        packet.entity_type = self.entity_type
        return packet
    end;
    asUpdatePacket = function(self)
        local packet = Entity.asUpdatePacket(self)
        packet.x_vel = tostring(round_to_nth_decimal(self.velocity.x,2))
        packet.y_vel = tostring(round_to_nth_decimal(self.velocity.y,2))
        packet.entity_type = self.entity_type
        return packet
    end;
}

Fireball = Class{ _includes = Projectile,
    init = function(self, position, owner, acceleration, velocity, width, height)
        local perpendicular = velocity:perpendicular():angleTo()
        local adjustedX = position.x - width/2*math.cos(perpendicular)
        local adjustedY = position.y - height/2*math.sin(perpendicular)

        Projectile.init(self, vector(adjustedX, adjustedY), owner, acceleration, velocity, width, height)
        self.projectile_type = "FIREBALL"
        self.hitbox = HC.polygon(calculateProjectileHitbox(
        		adjustedX, adjustedY, velocity,
        		width, height))
        self.hitbox.owner = owner
        self.hitbox.type = "PROJECTILE"
        self.hitbox:rotate(math.pi/2, adjustedX, adjustedY)
    end;
    asSpawnPacket = function(self)
        local packet = Projectile.asSpawnPacket(self)
        packet.projectile_type = self.projectile_type
        return packet
    end;
    asUpdatePacket = function(self)
        return Projectile.asUpdatePacket(self)
    end;
}

function spawn_projectile(x, y, velocity_vector, owner)
    log("[DEBUG] Spawning projectile with owner: " .. owner)
    new_projectile = Fireball(vector(x,y), owner, 600, velocity_vector, 14, 19)
    local id = random_string(12)

    -- new_projectile.hitbox = HC.polygon(calculateProjectileHitbox(
    -- 		new_projectile.position.x, new_projectile.position.y, new_projectile.velocity,
    -- 		new_projectile.width, new_projectile.height))
    -- new_projectile.hitbox.owner = owner
    -- new_projectile.hitbox.type = new_projectile.entity_type
    -- new_projectile.hitbox:rotate(math.pi/2, new_projectile.position.x, new_projectile.position.y) --should this be angleTo(0,0)?

    local x1,y1,x2,y2,x3,y3,x4,y4 = new_projectile.hitbox._polygon:unpack()
    while world["entities"][id] ~= nil do
        id = id .. 'a'
    end
    world["entities"][id] = new_projectile
    --TODO: Start player cooldown (and check the skill is ready in the first place)

    broadcast_projectile_spawn_packet(new_projectile, id)

    Timer.after(5, function()
        remove_entity(id)
    end)

    broadcast_debug_packet("+".. new_projectile.entity_type .. " " .. id, {
        x1=tostring(x1),y1=tostring(y1),
        x2=tostring(x2),y2=tostring(y2),
        x3=tostring(x3),y3=tostring(y3),
        x4=tostring(x4),y4=tostring(y4)
        }
    )
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
