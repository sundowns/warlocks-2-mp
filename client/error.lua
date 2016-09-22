error = {} -- the error state

function error:init()
  error_message = "Undefined error"
end

function error:enter(previous, msg)
  set_font_size(16)
  love.graphics.setBackgroundColor(96, 96, 96)
  error_message = msg
end

function error:leave()
  reset_colour()
  reset_font()
end

function error:update(dt)
end

function error:draw()
  love.graphics.print(error_message, love.graphics.getWidth()/2 - 50, love.graphics.getHeight()/2)
end
