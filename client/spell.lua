Projectile = Class{ _includes = Entity,
    init = function(self, name, position, velocity, projectile_type, height, width)
        Entity.init(self, name, position, velocity, "PROJECTILE", "DEFAULT")
        self.projectile_type = projectile_type
        self.height = height
        self.width = width
    end;
    move = function(self, newX, newY)
        Entity.move(self, newX, newY)
        --self.hitbox:moveTo(newX, newY)
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
    end;
    move = function(self, newX, newY)
        Projectile.move(self, newX, newY)
    end;
}
