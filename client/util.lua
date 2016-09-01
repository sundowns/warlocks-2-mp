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

function random_string(l)
  if l < 1 then return nil end
  local stringy=""
  for i=1,l do
    stringy=stringy..random_letter()
  end
  return stringy
end

function random_letter()
    return string.char(math.random(97, 122));
end

function round_to_nth_decimal(num, n)
  local mult = 10^(n or 0)
  return math.floor(num * mult + 0.5) / mult
end

function create_json_packet(payload, cmd, alias)
  if alias then payload.alias = alias end
  payload.cmd = cmd
  return json.encode(payload)
end