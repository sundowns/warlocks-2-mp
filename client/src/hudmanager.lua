HudManager = Class{
    init = function(self)
        self.images = {}
        self.imageSize = 48
        self.canvas = love.graphics.newCanvas(love.graphics.getWidth()*0.4, self.imageSize)
        self.origin = vector(0, love.graphics.getHeight() - self.imageSize)
        self.canvasDirty = true --flag to update HUD canvas next update call (no point recalculating if nothing changed)
    end;
    update = function(self)
        if self.canvasDirty then
            love.graphics.setCanvas(self.canvas)
                love.graphics.clear()
                love.graphics.setBlendMode("alpha")
                love.graphics.setColor(constants.COLOURS.HUD_BACKGROUND:get())
                love.graphics.rectangle('fill', 0,0, self.canvas:getWidth(), self.canvas:getHeight())
                local currentX = 0
                for i = 1, 5 do
                    if player.spellbook.spells['SPELL' .. i] then
                        self:renderSpell(player.spellbook.spells['SPELL' .. i], currentX)
                    end
                    currentX = currentX + self.imageSize
                end
            love.graphics.setCanvas()
            self.canvasDirty = false
        end
    end;
    draw = function(self)
        love.graphics.draw(self.canvas, self.origin.x, self.origin.y)
    end;
    markDirty = function(self)
        self.canvasDirty = true
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
