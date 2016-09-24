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
