ScoreManager = Class{
    init = function(self)
        self.canvas = love.graphics.newCanvas(love.graphics.getWidth()*0.8, love.graphics.getHeight()*0.8)
        self.canvas:setFilter('nearest', 'nearest')
        self.canvas_x = love.graphics.getWidth()*0.1
        self.canvas_y = love.graphics.getHeight()*0.1
        love.graphics.setCanvas(self.canvas)
            love.graphics.clear()
            love.graphics.setBlendMode("alpha")
            set_font(32, 'debug')
            love.graphics.print("Scoreboard", 16, -16)
            love.graphics.setColor(200, 180, 110, 100)
            love.graphics.rectangle('fill', 0,0, self.canvas:getWidth(), self.canvas:getHeight())
        love.graphics.setCanvas()
    end;
    draw = function(self)
        love.graphics.draw(self.canvas, self.canvas_x, self.canvas_y)
    end;
}
