Entity = Class{
    init = function(self, id, position, type)
        self.id = id
        self.position = position
        self.entity_type = type
        self.scheduleUpdate = false
    end;
    move = function(self, inX, inY)
        self.position = vector(inX, inY)
    end;
    asSpawnPacket = function(self)
        return {
            id = id,
            x = tostring(self.position.x),
            y = tostring(self.position.y),
            width = self.width,
            height = self.height
        }
    end;
    asUpdatePacket = function(self)
        return {
            id = id,
            x = tostring(round_to_nth_decimal(self.position.x,2)),
            y = tostring(round_to_nth_decimal(self.position.y)),
            width = self.width,
            height = self.height
        }
    end;
}

Explosion = Class{ _includes = Entity,
    init = function(self, id, position, radius, owner, time_to_live)
        Entity.init(self, id, position, "EXPLOSION")
        self.radius = radius
        self.hitbox = HC.circle(position.x,position.y, radius)
        self.hitbox.owner = owner
        self.hitbox.parent = self
        self.hitbox.id = id
        self.time_to_live = time_to_live
    end;
    move = function(self, inX, inY)
        Entity.move(self, inX, inY)
        self.hitbox:moveTo(inX, inY)
    end;
    asSpawnPacket = function(self)
        local packet = Entity.asSpawnPacket(self)
        packet.entity_type = self.entity_type
        packet.radius = self.radius
        return packet
    end;
    asUpdatePacket = function(self)
        local packet =  Entity.asUpdatePacket(self)
        packet.entity_type = self.entity_type
        packet.radius = self.radius
        return packet
    end;
}


function spawn_explosion(x, y, radius, owner, time_to_live)
    local id = random_string(12)
    while world["entities"][id] ~= nil do
        id = id .. 'a'
    end
    local new_explosion  = Explosion(id, vector(x,y), radius, owner, time_to_live)
    world["entities"][id] = new_explosion

    broadcast_projectile_explosion_packet(new_explosion, id)

    Timer.after(new_explosion.time_to_live, function()
        remove_entity(id)
    end)
end
