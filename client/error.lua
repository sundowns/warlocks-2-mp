error = {} -- the error state

function error:init()
  error_line1 = "Undefined error"
  error_line2 = nil
end

function error:enter(previous, line1, line2)
  love.graphics.setBackgroundColor(96, 96, 96)
  error_line1 = line1
  error_line2 = line2
end

function error:leave()
  reset_colour()
  reset_font()
end

function error:update(dt)
end

function error:draw()
  set_font_size(32)
  love.graphics.print(error_line1, love.graphics.getWidth()/2 - 100, love.graphics.getHeight()/2-50)
  if error_line2 then
    set_font_size(16)
    love.graphics.print(error_line2, love.graphics.getWidth()/2 - 100, love.graphics.getHeight()/2)
  end
end
