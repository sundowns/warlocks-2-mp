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

--DONT USE JSON, USE SOME BINARY SERIALISATION OR SUMMIN. JSON IS SLOW
function create_json_packet(payload, cmd, alias)
  if alias then payload.alias = alias end
  payload.cmd = cmd
  return json.encode(payload)
end

function dbg(msg)
  if settings.debug then print(msg) end
end

--Consider putting these camera functions somewhere else more appropriate..
function prepare_camera()
	camera = Camera(0, 0)
	camera:zoom(1.25)
end

function update_camera()
	local camX, camY = camera:position()
	local newX, newY = camX, camY
	if (player.x > camX + love.graphics.getWidth()*0.05) then
		newX = player.x - love.graphics.getWidth()*0.05
	end
	if (player.x < camX - love.graphics.getWidth()*0.05) then
		newX = player.x + love.graphics.getWidth()*0.05
	end
	if (player.y > camY + love.graphics.getHeight()*0.035) then
		newY = player.y - love.graphics.getHeight()*0.035
	end
	if (player.y < camY - love.graphics.getHeight()*0.035) then
		newY = player.y + love.graphics.getHeight()*0.035
	end

	--camera:lookAt(newX, newY)
	camera:lockPosition(newX, newY, camera.smooth.damped(1))
end

function print_table(it, name)
  if name then dbg("Printing table: " .. name) end
  for k, v in pairs(it) do
    dbg("[key]: " .. tostring(k) .. " | [value]: " .. tostring(v))
  end
end
