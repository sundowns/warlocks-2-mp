local psystem = nil


function love.load()
    local img = love.graphics.newImage('effect.png')
    psystem = love.graphics.newParticleSystem(img, 64)
    psystem:setQuads(love.graphics.newQuad(0, 32, 16, 16, img:getDimensions()), love.graphics.newQuad(16, 32, 16, 16, img:getDimensions()),
    love.graphics.newQuad(32, 32, 16, 16, img:getDimensions()), love.graphics.newQuad(48, 32, 16, 16, img:getDimensions()))
    psystem:setEmissionRate(10)
    psystem:setLinearAcceleration(-50, -50, 50, 50) -- Randomized movement towards the bottom of the screen.
    psystem:setRotation(0, math.pi)
    psystem:setParticleLifetime(0.5, 2)
end

function love.update(dt)
    psystem:update(dt)
end

function love.draw()
    love.graphics.draw(psystem, love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    love.graphics.print("press space if ur cool", 10, love.graphics.getHeight()-30)
end

function love.keypressed(key)
	if key == 'space' then
        if psystem:isPaused() then
            psystem:start()
        else
            psystem:pause()
        end
	end
end
