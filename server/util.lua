function build_packet_string(...)
	local packet_string = ""
	for i,v in ipairs(arg) do
		if i == 0 then
			packet_string = packet_string .. tostring(v) 
		else
			packet_string = '|' .. packet_string .. tostring(v) 
		end
    
  end
  return packet_string
end