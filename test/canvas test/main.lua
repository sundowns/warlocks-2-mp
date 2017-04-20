function love.load()
    show_canvas = false
    canvas = love.graphics.newCanvas(love.graphics.getWidth()/3, love.graphics.getHeight()/3)
    love.graphics.setCanvas(canvas)
        love.graphics.clear()
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.rectangle('fill', 0,0, canvas:getWidth(), canvas:getHeight())
    love.graphics.setCanvas()
    canvas_x = 0
    canvas_y = 0
end

function love.update(dt)
    canvas_x = love.mouse.getX()
    canvas_y = love.mouse.getY()
end

function love.draw()
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.circle('fill', love.graphics.getWidth()/2, love.graphics.getHeight()/2, love.graphics.getWidth()/3)
    love.graphics.setColor(0, 0, 255, 255)
    love.graphics.print("Press space to canvas it up", love.graphics.getWidth()/2, love.graphics.getHeight()*.75)

    if show_canvas then
        love.graphics.draw(canvas, canvas_x - canvas:getWidth()/2, canvas_y - canvas:getHeight()/2)
    end
end


function love.keypressed(key)
    if key == "space" then
        show_canvas = not show_canvas
    end
end
