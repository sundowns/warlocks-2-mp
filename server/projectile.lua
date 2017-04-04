Projectile = Class{ _includes = Entity,
    init = function(self, position, owner, acceleration, velocity, width, height)
        Entity.init(self, position, width, height)
        self.owner = owner
        self.entity_type = "PROJECTILE"
        self.acceleration = acceleration
        self.velocity = velocity
        local startX = position.x + width/2
        local startY = position.y + height/2

    end;
}

Fireball = Class{ _includes = Projectile,
    init = function(self, position, owner, acceleration, velocity, width, height)
        Projectile.init(self, position, owner, acceleration, velocity, width, height)
        self.projectile_type = "FIREBALL"
    end;
}

function spawn_projectile(x, y, velocity_vector, owner)
    log("[DEBUG] Spawning projectile with owner: " .. owner)
    new_projectile = Fireball(vector(x,y), owner, 600, velocity_vector, 14, 19)
    -- local new_projectile = {
    --     position = vector(x,y),
    --     velocity = velocity_vector,
    --     acceleration = 600,
    --     entity_type = "PROJECTILE",
    --     projectile_type = "FIREBALL",
    --     owner = owner,
    --     width = 14,
    --     height = 19
    -- }
    --local startX = player.x + player.width/2
-- 	local startY = player.y + player.height/2
-- 	local p_angle = math.atan2((y  - startY), (x  - startX))
-- 	local perpendicular = p_angle -1.6
-- 	if perpendicular < -3.2 then
-- 		perpendicular = 3.2
-- 	end
-- 	--LEFT QUADRANT SEEMS TO BE OFF, IDK WHY LMAO HAHA
-- 	local adjustedX = player.x + player.width*0.4 +math.cos(perpendicular) * spell.size * player.modifier_aoe * spell.animation[1]:getWidth()/2
-- 	local adjustedY = player.y + player.width*0.4 +math.sin(perpendicular) * spell.size * player.modifier_aoe * spell.animation[1]:getWidth()/2
--
-- 	local p_Dx = spell.speed * math.cos(p_angle)
-- 	local p_Dy = spell.speed * math.sin(p_angle)



    local id = random_string(12)



    new_projectile.hitbox = HC.polygon(calculateProjectileHitbox(
    		new_projectile.position.x, new_projectile.position.y, new_projectile.velocity:angleTo(),
    		new_projectile.width, new_projectile.height))
    new_projectile.hitbox.owner = owner
    new_projectile.hitbox.type = new_projectile.entity_type
    new_projectile.hitbox:rotate(velocity_vector:angleTo(vector(0,-1))) --should this be angleTo(0,0)?
    print_table(new_projectile)
    local x1,y1,x2,y2,x3,y3,x4,y4 = new_projectile.hitbox._polygon:unpack()
    while world["entities"][id] ~= nil do
        id = id .. 'a'
    end
    world["entities"][id] = new_projectile
    --TODO: Start player cooldown (and check the skill is ready in the first place)
    Timer.after(5, function()
        remove_entity(id)
    end)
    broadcast_debug_packet("+".. new_projectile.entity_type .. " " .. id, {
        x1=tostring(x1),y1=tostring(y1),
        x2=tostring(x2),y2=tostring(y2),
        x3=tostring(x3),y3=tostring(y3),
        x4=tostring(x4),y4=tostring(y4)
        }
    )
end

-- function castLinearProjectile(player, spell, x, y)
-- 	local startX = player.x + player.width/2
-- 	local startY = player.y + player.height/2
-- 	local p_angle = math.atan2((y  - startY), (x  - startX))
-- 	local perpendicular = p_angle -1.6
-- 	if perpendicular < -3.2 then
-- 		perpendicular = 3.2
-- 	end
-- 	--LEFT QUADRANT SEEMS TO BE OFF, IDK WHY LMAO HAHA
-- 	local adjustedX = player.x + player.width*0.4 +math.cos(perpendicular) * spell.size * player.modifier_aoe * spell.animation[1]:getWidth()/2
-- 	local adjustedY = player.y + player.width*0.4 +math.sin(perpendicular) * spell.size * player.modifier_aoe * spell.animation[1]:getWidth()/2
--
-- 	local p_Dx = spell.speed * math.cos(p_angle)
-- 	local p_Dy = spell.speed * math.sin(p_angle)
--
-- 	newProjectile = {
-- 		x = adjustedX,
-- 		y = adjustedY,
-- 		dx = p_Dx,
-- 		dy = p_Dy,
-- 		angle = p_angle,
-- 		img = spell.img,
-- 		time_to_live = spell.lifespan * player.modifier_range,
-- 		size = spell.size * player.modifier_aoe,
-- 		size_modifier = player.modifier_aoe,
-- 		currentFrame = 1,
-- 		animation = spell.animation,
-- 		owner = player.name,
-- 		hitbox = nil,
-- 		width = spell.size * player.modifier_aoe * spell.animation[1]:getWidth(),
-- 		height = spell.size * player.modifier_aoe * spell.animation[1]:getHeight(),
-- 		frameTimer = spell.frameTimer,
-- 		timeBetweenFrames = spell.timeBetweenFrames,
-- 		originX = adjustedX,
-- 		originY = adjustedY,
-- 		spell = spell
-- 	}
--
-- 	newProjectile.hitbox = HC.polygon(calculateProjectileHitbox(
-- 		newProjectile.x, newProjectile.y, newProjectile.angle,
-- 		newProjectile.width, newProjectile.height))
-- 	newProjectile.hitbox.owner = newProjectile.owner
-- 	newProjectile.hitbox.type = "SPELL"
-- 	newProjectile.hitbox.spell = "FIREBALL"
--
-- 	table.insert(projectiles, newProjectile)
--
-- end


function calculateProjectileHitbox(x1, y1, angle, width, height)
	local x2 = x1 + (width * math.cos(angle))
	local y2 = y1 + (width * math.sin(angle))
	local x3 = x1 + (height * math.cos(angle+1.6)) --idk why +1.5 radians is the perpendicular but hey, it works
	local y3 = y1 + (height * math.sin(angle+1.6))
	local x4 = x3 + (x2 - x1) -- x3 + the difference between x1 and x2
	local y4 = y3 + (y2 - y1)

	return x1, y1, x2, y2, x4, y4, x3, y3 -- vertices in clockwise order
end


-- function calculateProjectileCenter(x, y, angle, width, height)
-- 	local x1, y1, x2, y2, x3, y3, x4, y4 = calculateProjectileHitbox(x, y, angle, width, height)
--
-- 	local centroidX = (x1 + x2 + x3 + x4)/4
-- 	local centroidY = (y1 + y2 + y3 + y4)/4
--
-- 	return centroidX, centroidY
-- end
