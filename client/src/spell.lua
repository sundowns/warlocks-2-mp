local SpellIcons = {}
SpellIcons["FIREBALL"] = love.graphics.newImage("assets/ui/spell-fireball.png")
SpellIcons["PORTAL"] = love.graphics.newImage("assets/ui/spell-portal.png")

SpellBook = Class{
    init = function(self)
        self.spells = {}
    end;
    addSpell = function(self, slot, spell)
        self.spells[slot] = spell
        self.spells['_' .. spell.id] = spell
    end;
    getSpellBySlot = function(self, slot)
        return self.spells[slot]
    end;
    getSpellById = function(self, spell_id)
        return self.spells['_' .. spell_id]
    end;
    spellKeyPressed = function(self, slot)
        local spell = self:getSpellBySlot(slot)
        if not spell or not spell.ready then return end
        local at_x, at_y = love.mouse.getPosition()
        at_x,at_y = camera:worldCoords(at_x,at_y)
        local player_x, player_y = player:centre()
        spell:cast(at_x, at_y, player.x, player.y)
    end;
}

Spell = Class{
    init = function(self, id, cooldown)
        self.cooldown = 0
        self.cooldown_duration = cooldown
        self.id = id
        self.ready = true
        self.image = SpellIcons[id]
    end;
    startCooldown = function(self, elapsed)
        self.ready = false
        self.cooldown = self.cooldown_duration - elapsed
        Timer.every(0.1, function()
            hud:markDirty()
            self.cooldown = self.cooldown - 0.1
            if self.cooldown <= 0 then
                self.cooldown = 0
                self.ready = true
                return false
            end
        end)
    end;
    cast = function(self, data)
        data.spell_type = self.id
        send_action_packet("CASTSPELL", data)
    end
}

Fireball = Class{_includes=Spell,
    init = function(self)
        Spell.init(self, 'FIREBALL', 3) --cooldown needs 2 come from server
    end;
    startCooldown = function(self, elapsed)
        Spell.startCooldown(self, elapsed)
    end;
    cast = function(self, at_x, at_y, from_x, from_y)
        local data = {at_X=at_x, at_Y=at_y, player_x = from_x, player_y = from_y}
        Spell.cast(self, data)
    end;
}

Portal = Class{_includes=Spell,
    init = function(self)
        Spell.init(self, 'PORTAL', 12) --cooldown needs 2 come from server
    end;
    startCooldown = function(self, elapsed)
        Spell.startCooldown(self, elapsed)
    end;
    cast = function(self, at_x, at_y, from_x, from_y)
        local data = {at_X=at_x, at_Y=at_y, player_x = from_x, player_y = from_y}
        Spell.cast(self, data)
        self:startCooldown(0) --TODO: Make this prompted by the server accepting it
    end;
}
