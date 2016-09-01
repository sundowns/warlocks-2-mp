debug = false
client_version = "0.0.1"

username = ""
user_alive = false

function love.load()
	math.randomseed(os.time())
	require("util")
	require("network")
	require("world")
	require("player")
	love.graphics.setNewFont("assets/misc/IndieFlower.ttf", defaultFontSize)
	
	username = random_string(8)
	net_initialise()
	request_join()
end

function love.update(dt)
	worldTime = worldTime + dt
	if worldTime > updateRate then
		if user_alive then
			local dg = string.format("%s %s %f %f %f %f", player.name, "MOVE", player.x, player.y, player.x_vel, player.y_vel)
			udp:send(dg)
		end
		worldTime = worldTime-updateRate
	end

	if user_alive then
		process_input()
		calculate_player_movement(dt)
	end

	repeat
		data, msg = udp:receive()
		if data then 
			ent, cmd, params = data:match("^(%w+)%p(%w+)%p(.*)") 
			if cmd == "ENTITYAT" then --need to add velocity here so we can interpolate movement on client
				local x, y, ent_type, ent_colour = params:match("^(%-?[%d.e]*)|(%-?[%d.e]*)|(%a+)|(%a+)$")		
				assert(x and y and ent_type and ent_colour)
				x, y = tonumber(x), tonumber(y)
				if world[ent] == nil then
					add_entity(ent, ent_type, {name = ent, colour = ent_colour})
				else 
					world[ent].x = x
					world[ent].y = y
				end
			elseif cmd == 'ENTITYDESTROY' then
				local ent_type = params:match("^.*")
				remove_entity(ent, ent_type)
			elseif cmd == 'SERVERERROR' then
				print(tostring(params))
			elseif cmd == 'JOINACCEPTED' then
				prepare_player(username, tostring(params))
			else 
				print(data)
				print("unrecognised command:", cmd)
			end
		elseif msg ~= 'timeout' then
			error("Network error: " .. tostring(msg))
		end
	until not data	
end

function love.draw()
	reset_colour()
	for k, entity in pairs(world) do
		if entity.entity_type == "PLAYER" then
			love.graphics.draw(get_player_img(player), entity.x, entity.y)	
		elseif entity.entity_type == "ENEMY" then 
			local enemy = world[k]
			love.graphics.draw(get_enemy_img(enemy), enemy.x, enemy.y)	
		end	
	end
end

function love.quit()
	disconnect("Client closed by user")
end