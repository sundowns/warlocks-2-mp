HudManager = Class{
    init = function(self)
        self.images = {}
        self.imageSize = 48
        self.skills_canvas = love.graphics.newCanvas(love.graphics.getWidth()*0.4, self.imageSize)
        self.health_canvas = love.graphics.newCanvas(love.graphics.getWidth()*0.2, love.graphics.getHeight()*0.04)
        self.origin = vector(0, love.graphics.getHeight() - self.imageSize)
        self.skills_canvas_dirty = true --flag to update HUD canvas next update call (no point recalculating if nothing changed)
        self.health_canvas_dirty = true
        self.health_ratio = 1.0
        self.health_colours = {}
        self.health_colours['FULL'] = constants.COLOURS.HUD_HEALTH.FULL
        self.health_colours['DAMAGED'] = constants.COLOURS.HUD_HEALTH.DAMAGED
        self.health_colours['HURT'] = constants.COLOURS.HUD_HEALTH.HURT
        self.health_colours['WOUNDED'] = constants.COLOURS.HUD_HEALTH.WOUNDED
        self.health_colours['DYING'] = constants.COLOURS.HUD_HEALTH.DYING
        self.health_colours['DEAD'] = constants.COLOURS.HUD_HEALTH.DEAD
    end;
    getHealthColour = function(self)
        if self.health_ratio > 0.99 then
            return self.health_colours['FULL']
        elseif self.health_ratio > 0.80 then
            return self.health_colours['DAMAGED']
        elseif self.health_ratio > 0.6 then
            return self.health_colours['HURT']
        elseif self.health_ratio > 0.3 then
            return self.health_colours['WOUNDED']
        elseif self.health_ratio > 0 then
            return self.health_colours['DYING']
        else
            return self.health_colours['DEAD']
        end

    end;
    update = function(self)
        if self.skills_canvas_dirty then
            love.graphics.setCanvas(self.skills_canvas)
                love.graphics.clear()
                love.graphics.setBlendMode("alpha")
                love.graphics.setColor(constants.COLOURS.HUD_BACKGROUND:get())
                love.graphics.rectangle('fill',0,0, self.skills_canvas:getWidth(), self.skills_canvas:getHeight())
                local currentX = 0
                for i = 1, 5 do
                    if player.spellbook.spells['SPELL' .. i] then
                        self:renderSpell(player.spellbook.spells['SPELL' .. i], currentX)
                    end
                    currentX = currentX + self.imageSize
                end
            love.graphics.setCanvas()
            self.skills_canvas_dirty = false
        end
        if self.health_canvas_dirty then
            self.health_ratio = player.health/player.max_health
            local colour = self:getHealthColour()
            love.graphics.setCanvas(self.health_canvas)
                love.graphics.clear()
                love.graphics.setBlendMode("alpha")
                love.graphics.setColor(constants.COLOURS.HUD_BACKGROUND:get())
                love.graphics.rectangle('fill',0,0, self.health_canvas:getWidth(), self.health_canvas:getHeight())
                love.graphics.setColor(colour:get())
                love.graphics.rectangle('fill',0,0, self.health_canvas:getWidth()*self.health_ratio, self.health_canvas:getHeight())
            love.graphics.setCanvas()
           self.health_canvas_dirty = false
        end
    end;
    draw = function(self)
        love.graphics.draw(self.skills_canvas, self.origin.x, self.origin.y)
        love.graphics.draw(self.health_canvas, self.origin.x, self.origin.y - self.skills_canvas:getHeight())
    end;
    markSkillsDirty = function(self)
        self.skills_canvas_dirty = true
    end;
    markHealthDirty = function(self)
        self.health_canvas_dirty = true
    end;
    renderSpell = function(self, spell, x)
        local image = spell.image
        if image ~= nil then
            if spell.ready == false then
                love.graphics.setColor(180,180,180,170)
                love.graphics.draw(image, x, 0, 0, self.imageSize/(image:getWidth()), self.imageSize/(image:getHeight()))
                love.graphics.setColor(200,200,200,200)
                love.graphics.rectangle('fill', x, 0, self.imageSize, self.imageSize*spell.cooldown/spell.cooldown_duration)
                love.graphics.setColor(0,0,0,200)
                set_font(28, 'debug')
                love.graphics.print(round_to_nth_decimal(spell.cooldown,1), x + self.imageSize*0.1, 0-self.imageSize*0.17)
            else
                love.graphics.setColor(255,255,255,255)
                love.graphics.draw(image, x, 0, 0, self.imageSize/(image:getWidth()), self.imageSize/(image:getHeight()))
            end
        end
    end;
}
