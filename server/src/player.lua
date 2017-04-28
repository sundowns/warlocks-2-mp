Player = Class{ _includes = Entity,
    init = function(self, name, position, colour, client_index)
        Entity.init(self, name, position, "PLAYER")
        self.width = constants.DEFAULTS.PLAYER.width
        self.height = constants.DEFAULTS.PLAYER.height
        self.name = name
        self.colour = colour
        self.state = "STAND"
		self.orientation = "RIGHT"
        self.max_movement_velocity = constants.DEFAULTS.PLAYER.max_movement_velocity
        self.movement_friction = constants.DEFAULTS.PLAYER.movement_friction
		self.base_acceleration = constants.DEFAULTS.PLAYER.base_acceleration
		self.acceleration = constants.DEFAULTS.PLAYER.acceleration
        self.dash = { -- TODO does this do anything????
            acceleration = constants.DEFAULTS.PLAYER.dash_acceleration,
			duration = constants.DEFAULTS.PLAYER.dash_duration, --for some reason bitser hates decimals in tables?
			timer = constants.DEFAULTS.PLAYER.dash_timer,
			cancellable_after = constants.DEFAULTS.PLAYER.dash_cancellable_after --after timer is 0.7, so after 0.3seconds
        }
        self.index = client_index
        self.velocity = vector(0,0)
        self.hitbox = HC.circle(position.x,position.y,constants.DEFAULTS.PLAYER.width/2)
        self.hitbox.owner = name
        self.hitbox.type = "PLAYER"
        self.health = constants.DEFAULTS.PLAYER.health
        self.spellbook = {}
    end;
    asSpawnPacket = function(self)
        local packet = Entity.asSpawnPacket(self)
        packet.x_vel = tostring(self.velocity.x)
        packet.y_vel = tostring(self.velocity.y)
        packet.state = self.state
        packet.entity_type = self.entity_type
        packet.orientation = self.orientation
        packet.max_movement_velocity = self.max_movement_velocity
        packet.movement_friction = self.movement_friction
        packet.base_acceleration = self.base_acceleration
        packet.acceleration = self.acceleration
        packet.dash = self.dash
        packet.colour = self.colour
        packet.name = self.name
        return packet
    end;
    asUpdatePacket = function(self)
        local packet = Entity.asSpawnPacket(self)
        packet.x_vel = tostring(round_to_nth_decimal(self.velocity.x, 2))
        packet.y_vel = tostring(round_to_nth_decimal(self.velocity.y, 2))
        packet.colour = self.colour -- this is just for the initial creation on the client, kinda shit???
        packet.state = self.state
        packet.orientation = self.orientation
        packet.entity_type = self.entity_type
        return packet
    end;
    centre = function(self)
        if self.orientation == "LEFT" then
            return self.position.x + self.width/2, self.position.y - self.height/2
        elseif self.orientation == "RIGHT" then
            return self.position.x - self.width/2, self.position.y - self.height/2
        end
    end;
    move = function(self, newX, newY)
        Entity.move(self, newX, newY)
        self.hitbox:moveTo(newX, newY)
    end;
    addSpell = function(self, spell)
        self.spellbook[spell.id] = spell
    end;
    castSpell = function(self, spell_id, at_X, at_Y)
        if self.spellbook[spell_id] and self.spellbook[spell_id].ready then
            self.spellbook[spell_id]:cast(self, at_X, at_Y)
        end
    end;
    hitByProjectile = function(self, projectile_owner, projectile)
        --take a bit of damage for direct hit (more knockback too!!?)
        local final_delta = (projectile.velocity + self.velocity):normalizeInplace()
        self.velocity = self.velocity + projectile.velocity
        local new_pos = self.position +  final_delta * self.hitbox._radius
        self:move(new_pos.x, new_pos.y)
        if projectile.damage then
            self.health = self.health - projectile.damage
            print("new health is " .. self.health)
        end
    end;
}
