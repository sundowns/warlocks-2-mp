local binser = require 'binser'

function print_table(table, name)
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

local meta = {}
function meta.__index(table, key)
  print("im doing stuff")
  if key == 'alias' then
    return table[3]
  elseif key == 'tick'then
    return table[2]
  else
    return table[1][key]
  end
end

local original = {
  name = "smart guy",
  x = 10,
  y = 40,
  wtfsrs = "yes"
}

local serialised = binser.serialize(original, 100, 'alias')
local deserialised = binser.deserialize(serialised)
setmetatable(deserialised, meta)

print_table(deserialised, "data")
print(deserialised.tick)
