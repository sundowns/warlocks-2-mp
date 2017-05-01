Spell = Class {
    init = function(self, id, cooldown)
        self.id = id
        self.cooldown_duration = cooldown
        self.cooldown = 0
        self.ready = true
    end;
    cast = function(self)
        self.ready = false
        self.cooldown = self.cooldown_duration
        Timer.every(0.05, function()
            self.cooldown = self.cooldown - 0.05
            if self.cooldown <= 0 then
                self.cooldown = 0
                self.ready = true
                return false --stops the timer
            end
        end)
    end;
}

Fireball = Class { _includes = Spell,
    init = function(self)
        Spell.init(self, "FIREBALL", constants.DEFAULTS.FIREBALL.cooldown)
        self.impact_force = 60 -- TODO: use this for knockback stuff
    end;
    cast = function(self, caster, at_X, at_Y)
        local vector = calc_vector_from_points(caster.position.x, caster.position.y, at_X, at_Y)
        local nVector = (vector+caster.velocity):normalized()
        local spawnPosition = nVector*caster.velocity:len()*constants['TICKRATE']
        local spawnX = caster.position.x + nVector.x*caster.width
        local spawnY = caster.position.y + nVector.y*caster.height
        spawn_projectile(spawnX, spawnY, vector, caster.name, self.impact_force)

        Spell.cast(self)
    end;
}
