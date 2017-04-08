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
        -- self.hitbox = HC.circle(self.x,self.y,self.width/2)
        -- self.hitbox.owner = self.name
    	-- self.hitbox.type = "PLAYER"
        --self.hasCollidedWith = {}
    end;
    centre = function(self)
        if self.orientation == "LEFT" then
            return self.position.x + self.width/2, self.position.y - self.height/2
        elseif self.orientation == "RIGHT" then
            return self.position.x - self.width/2, self.position.y - self.height/2
        end
    end;
    move = function(self, newX, newY)
        print("new: " .. newX .. ", " .. newY)
        Entity.move(self, newX, newY)
        self.hitbox:moveTo(newX, newY)
    end;
    castSpell = function(self, spell, at_X, at_Y)
        if spell == "FIREBALL" then
            self:castFireball(at_X, at_Y)
        end
    end;
    castFireball = function(self, at_X, at_Y)
        local vector = calc_vector_from_points(self.position.x, self.position.y, at_X, at_Y)
        local nVector = (vector+self.velocity):normalized()
        local spawnPosition = nVector*self.velocity:len()*constants['TICKRATE']
        local spawnX = self.position.x + nVector.x*self.width
        local spawnY = self.position.y + nVector.y*self.height
        spawn_projectile(spawnX, spawnY, vector, self.name)
    end;
    hitByProjectile = function(self, projectile_owner, projectile, delta, dt)
        --take a bit of damage for direct hit (more knockback too!!?)
        self.velocity = self.velocity + delta * projectile.acceleration * dt
        local new_pos = self.position +  delta * self.hitbox._radius * dt
        self:move(new_pos.x, new_pos.y)
    end;
}

function spawn_player(name, x, y, client_index)
    local colour =  client_list[client_index].colour
	local new_player = Player(name, vector(x, y),colour, client_index)
	world["players"][payload.alias] = new_player

	return new_player
end
