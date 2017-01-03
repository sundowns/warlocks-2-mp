error_screen = {} -- the error state

function error_screen:init()
  error_line1 = "Undefined error"
  error_line2 = nil
end

function error_screen:enter(previous, line1, line2)
  love.graphics.setBackgroundColor(96, 96, 96)
  love.graphics.setColor(255,50,50,255)
  error_line1 = line1
  error_line2 = line2
end

function error_screen:leave()
  reset_colour()
  reset_font()
end

function error_screen:update(dt)
end

function error_screen:draw()
  set_font(32, 'debug')
  love.graphics.print(error_line1, love.graphics.getWidth()/2 - 100, love.graphics.getHeight()/2-50)
  if error_line2 then
    set_font(16, 'debug')
    love.graphics.print(error_line2, love.graphics.getWidth()/2 - 100, love.graphics.getHeight()/2)
  end
end
