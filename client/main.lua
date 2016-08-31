debug = false

function love.load()
	require("util")
	require("network")
	require("world")
	require("player")
	love.graphics.setNewFont("assets/misc/IndieFlower.ttf", defaultFontSize)
	
	net_initialise()
	prepare_player()
	request_join()
end

function love.update(dt)
	worldTime = worldTime + dt

	if worldTime > updateRate then
		local dg = string.format("%s %s %f %f", player.name, "velocity", player.x_vel, player.y_vel)
		udp:send(dg)
		worldTime = worldTime-updateRate -- set t for the next round
	end

	repeat
		data, msg = udp:receive()
		if data then 
			ent, cmd, params = data:match("^(%S*) (%S*) (.*)")
			if cmd == "entity_at" then

				local x, y = params:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
				assert(x and y)
				x, y = tonumber(x), tonumber(y)
				world[ent].x = x
				world[ent].y = y
				print('we updating entity position x:' .. x .. " y:" .. y)
			else
				print("unrecognised command:", cmd)
			end
		elseif msg ~= 'timeout' then
			error("Network error: " .. tostring(msg))
		end
	until not data	

	process_input()
end

function love.draw()
	reset_colour()
	for k, entity in pairs(world) do
		if entity.entity_type == "PLAYER" then
			love.graphics.draw(get_player_img(player), entity.x, entity.y)	
		end	
	end
end