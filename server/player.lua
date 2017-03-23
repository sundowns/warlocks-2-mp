--TODO: Replace existing stuff with classes like below
Entity = Class{
    init = function(self, x, y)
        self.x = x
        self.y = y
    end;
}

Player = Class { _includes = Entity,
    init = function(self, x, y, name, colour, client_index)
        Entity.init(self, x, y)
        self.name = name
        self.colour = colour
        self.entity_type = "PLAYER"
        self.state = "STAND"
		self.orientation = "RIGHT"
        self.max_movement_velocity = constants.DEFAULTS.PLAYER.max_movement_velocity
        self.movement_friction = constants.DEFAULTS.PLAYER.movement_friction
		self.base_acceleration = constants.DEFAULTS.PLAYER.base_acceleration
		self.acceleration = constants.DEFAULTS.PLAYER.acceleration
        self.x_vel = 0 -- TODO think these are redundant/can be removed if u clean up network.
        self.y_vel = 0 -- TODO think these are redundant/can be removed if u clean up network.
        self.dash = { -- TODO does this do anything????
            acceleration = constants.DEFAULTS.PLAYER.dash_acceleration,
			duration = constants.DEFAULTS.PLAYER.dash_duration, --for some reason bitser hates decimals in tables?
			timer = constants.DEFAULTS.PLAYER.dash_timer,
			cancellable_after = constants.DEFAULTS.PLAYER.dash_cancellable_after --after timer is 0.7, so after 0.3seconds
        }
        self.width = constants.DEFAULTS.PLAYER.width
        self.height = constants.DEFAULTS.PLAYER.height
        self.index = client_index
        self.velocity = vector(0,0)
        self.hitbox = HC.circle(self.x,self.y,self.width/2)
        self.hitbox.owner = self.name
    	self.hitbox.type = "PLAYER"
        self.hasCollidedWith = {}
    end;
}

function spawn_player(name, x, y, client_index)
    local colour =  client_list[client_index].colour
	local new_player = Player(x,y,name,colour, client_index)

    --Why do we have to do it this way again? Test putting in constructor before placing into world collection
	world["players"][payload.alias] = new_player

	return new_player
end

function move_player(inPlayer, x, y)
    inPlayer.x = x
    inPlayer.y = y
    inPlayer.hitbox:moveTo(x, y)
    return inPlayer
end

function player_cast_fireball(player_x, player_y, at_X, at_Y, alias)
    local vector = calc_vector_from_points(player_x, player_y, at_X, at_Y)
    spawn_projectile(player_x, player_y, vector, alias)
end

function calc_vector_from_points(fromX, fromY, toX, toY)
    local vec = vector(toX-fromX, toY-fromY)
    return vec
end
