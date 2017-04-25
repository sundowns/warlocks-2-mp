HudManager = Class{
    init = function(self)
        self.images = {}
        self.images["SPELL1"] = love.graphics.newImage("assets/ui/spell-fireball.png")
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

                for k, spell in pairs(player.spellbook.spells) do
                    local image = self.images[k]
                    if image ~= nil then
                        -- spellbook should be a table with this image data, this manager should simply handle loading them in/out of memory
                        love.graphics.setColor(255,255,255,255)
                        love.graphics.draw(image, currentX, 0, 0, self.imageSize/(image:getWidth()), self.imageSize/(image:getHeight()))
                        if spell.ready == false then
                            love.graphics.setColor(200,200,200,150)
                            love.graphics.rectangle('fill', currentX, 0, self.imageSize, self.imageSize*spell.cooldown/spell.cooldown_duration)
                            love.graphics.setColor(0,0,0,200)
                            set_font(28, 'debug')
                            love.graphics.print(round_to_nth_decimal(spell.cooldown,1), currentX + self.imageSize*0.1, 0)
                        end
                        currentX = currentX + self.imageSize

                    end
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
}
