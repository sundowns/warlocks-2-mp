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

function print_table(table, name)
  log("==================")
  if name then print("Printing table: " .. name) end
  for k, v in pairs(table) do
    if type(v) == "table" then
      print("[table]: " .. tostring(k))
      for key, val in pairs(v) do
        print(" *[key]: " .. tostring(key) .. " | [value]: " .. tostring(val))
      end
    else
      print("[key]: " .. tostring(k) .. " | [value]: " .. tostring(v))
    end
  end
end

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function within_variance(val1, val2, variance)
  local diff = math.abs(val1 - val2)
  if diff < variance then
    return true
  else
    return false
  end
end

function math.clamp(val, min, max)
    if min - val > 0 then
        return min
    end
    if max - val < 0 then
        return max
    end
    return val
end

function merge_tables(base, additions)
    for k,v in pairs(additions) do
        base[k] = v
    end
    return base
end

function random_string(l) --this is probably a bad way to do this. Try some form of hashing os time??
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

function log(msg)
    print("[".. tick .."] " .. msg)
end

function calc_vector_from_points(fromX, fromY, toX, toY)
    local vec = vector(toX-fromX, toY-fromY)
    return vec
end
