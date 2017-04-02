Projectile = Class{ _includes = Entity,
    init = function(self, x, y, owner, acceleration, velocity, width, height)
        Entity.init(x, y, width, height)
        self.owner = owner
        self.entity_type = "PROJECTILE"
        self.acceleration = acceleration
        self.velocity = velocity
    end;
}

Fireball = Class{ _includes = Projectile,
    init = function(self, x, y, owner, acceleration, velocity, width, height)
        Projectile.init(x, y, owner, acceleration, velocity, width, height)
        self.projectile_type = "FIREBALL"
    end;
}

--TODO: Add position, width, and height to projectiles/fireball.
