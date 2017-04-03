Projectile = Class{ _includes = Entity,
    init = function(self, x, y, owner, acceleration, velocity, width, height)
        Entity.init(x, y, width, height)
        self.owner = owner
        self.entity_type = "PROJECTILE"
        self.acceleration = acceleration
        self.velocity = velocity
    end;
}

Fireball = Class{ _includes = Projectile,
    init = function(self, x, y, owner, acceleration, velocity, width, height)
        Projectile.init(x, y, owner, acceleration, velocity, width, height)
        self.projectile_type = "FIREBALL"
    end;
}



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


-- function calculateProjectileHitbox(x1, y1, angle, width, height)
-- 	local x2 = x1 + (width * math.cos(angle))
-- 	local y2 = y1 + (width * math.sin(angle))
-- 	local x3 = x1 + (height * math.cos(angle+1.6)) --idk why +1.5 radians is the perpendicular but hey, it works
-- 	local y3 = y1 + (height * math.sin(angle+1.6))
-- 	local x4 = x3 + (x2 - x1) -- x3 + the difference between x1 and x2
-- 	local y4 = y3 + (y2 - y1)
--
-- 	return x1, y1, x2, y2, x4, y4, x3, y3 -- vertices in clockwise order
-- end


-- function calculateProjectileCenter(x, y, angle, width, height)
-- 	local x1, y1, x2, y2, x3, y3, x4, y4 = calculateProjectileHitbox(x, y, angle, width, height)
--
-- 	local centroidX = (x1 + x2 + x3 + x4)/4
-- 	local centroidY = (y1 + y2 + y3 + y4)/4
--
-- 	return centroidX, centroidY
-- end
