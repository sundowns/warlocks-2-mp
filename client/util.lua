defaultFontSize = 14

function math.clamp(val, min, max)
    if min - val > 0 then
        return min
    end
    if max - val < 0 then
        return max
    end
    return val
end

function reset_colour()
	love.graphics.setColor(255, 255, 255, 255)
end

function reset_font()
	love.graphics.setNewFont("assets/misc/IndieFlower.ttf", defaultFontSize)
end

function set_font_size(size)
	love.graphics.setNewFont("assets/misc/IndieFlower.ttf", size)
end

function calculate_direction_with_two_points(x1, y1, x2, y2)
    local slope = (y2-y1)/(x2-x1)
    local y_intercept = y1 - slope*x1 -- b = y -mx
    local newX = x2 + 1
    local newY = slope*newX + y_intercept
    local dx = x2 - newX 
    local dy = y2 - newY

    return dx, dy
end