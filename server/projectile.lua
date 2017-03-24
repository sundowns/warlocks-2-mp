Projectile = Class{ _includes = Entity,
    init = function(self, x, y, owner, acceleration, velocity)
        Entity.init(x, y)
        self.owner = owner
        self.entity_type = "PROJECTILE"
        self.acceleration = acceleration
        self.velocity = velocity
    end;
}

Fireball = Class{ _includes = Projectile,
    init = function(self, x, y, owner, acceleration, velocity)
        Projectile.init(x, y, owner, acceleration, velocity)
        self.projectile_type = "FIREBALL"
    end;
}

--TODO: Add position, width, and height to projectiles/fireball. 
