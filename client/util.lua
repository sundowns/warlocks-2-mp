fonts = {}
local defaultFontSize = 14
local font_families = {
  game = "IndieFlower",
  debug = "BalooBhaina-Regular"
}
fonts['game'] = {}

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
  set_font(defaultFontSize, 'game')
end

function set_font(size, family)
  local font = font_families[family]

  if fonts[family] and fonts[family][size] then
    love.graphics.setFont(fonts[family][size])
  else
    if not fonts[family] then
      fonts[family] = {}
    end
    if fonts[family][size] then
      love.graphics.setFont(fonts[family][size])
    else
      fonts[family][size] = love.graphics.newFont("assets/misc/".. font ..".ttf", size)
      love.graphics.setFont(fonts[family][size])
    end
  end
end
set_font(defaultFontSize, 'game')

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

function dbg(msg)
  if settings.debug then print(msg) end
end

function print_table(table, force, name)
  local printer = dbg
  if force then printer = print end
  if name then printer("Printing table: " .. name) end
  for k, v in pairs(table) do
    if type(v) == "table" then
      printer("[table]: " .. tostring(k))
      for key, val in pairs(v) do
        printer(" *[key]: " .. tostring(key) .. " | [value]: " .. tostring(val))
      end
    else
      printer("[key]: " .. tostring(k) .. " | [value]: " .. tostring(v))
    end
  end
end

function within_variance(val1, val2, variance)
  local diff = math.abs(val1 - val2)
  if diff < variance then
    return true
  else
    return false
  end
end

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function point_is_in_rectangle(pointX, pointY, rectX, rectY, width, height)
  return pointX >= rectX and
         pointX <= rectX + width and
         pointY >= rectY and
         pointY <= rectY + height
end
