debug = false

function love.load()
	math.randomseed(os.time())
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
		local dg = string.format("%s %s %f %f %f %f", player.name, "move", player.x, player.y, player.x_vel, player.y_vel)
		udp:send(dg)
		worldTime = worldTime-updateRate -- set t for the next round
	end

	repeat
		data, msg = udp:receive()
		if data then 
			ent, cmd, params = data:match("^(%S*) (%S*) (.*)")
			if cmd == "entity_at" then
				local ent_name, x, y, ent_type, ent_colour = params:match("^(%a+) | (%-?[%d.e]*) (%-?[%d.e]*) | (%a+) | (%a+)$")
				assert(ent_type)
				assert(ent_colour)
				assert(name and x and y and ent_type and ent_colour)
				x, y = tonumber(x), tonumber(y)
				if not world[ent] then
					add_entity(ent, ent_type, {name = ent_name, colour = ent_colour})
				end
				world[ent].x = x
				world[ent].y = y
				print('we updating entity position x:' .. x .. " y:" .. y)
			elseif cmd == 'server_error' then
				local message = params:match("^.*")
				print(message)
			else
				print("unrecognised command:", cmd)
			end
		elseif msg ~= 'timeout' then
			error("Network error: " .. tostring(msg))
		end
	until not data	

	process_input()
	calculate_player_movement(dt)
end

function love.draw()
	reset_colour()
	for k, entity in pairs(world) do
		if entity.entity_type == "PLAYER" then
			love.graphics.draw(get_player_img(player), entity.x, entity.y)	
		end	
	end

	for k, enemy in pairs(enemies) do
		love.graphics.draw(get_enemy_img(enemy), enemy.x, enemy.y)	
	end
end