function build_packet(entity, command, dataList)
	local params = build_params(dataList)
  	return entity .. "," .. command .. "," .. params
end

function build_params(args)
	local paramString = ""
	local first = true
	for i,v in ipairs(args) do
		if first then
			paramString = paramString .. tostring(v)
			first = false
		else
			paramString = paramString .. '|' .. tostring(v)
		end
	end
  return paramString
end

function round_to_nth_decimal(num, n)
  local mult = 10^(n or 0)
  return math.floor(num * mult + 0.5) / mult
end

--DONT USE JSON ITS FKN SLOW NOOB. Use it to read settins file tho that's sexy
function create_json_packet(payload, cmd, alias)
  if alias then payload.alias = alias end
  payload.cmd = cmd
  return json.encode(payload)
end

function create_player_payload(player)
	return {x = player.x, y = player.y, x_vel = player.x_vel, y_vel = player.y_vel, colour = player.colour, entity_type = "PLAYER"}
end
