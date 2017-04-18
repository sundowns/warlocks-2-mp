local particleSystem = nil


function love.load()
    local img = love.graphics.newImage('effect.png')
    particleSystem = love.graphics.newParticleSystem(img, 10)
    particleSystem:setEmissionRate(5)
    particleSystem:setParticleLifetime(3, 5)
    particleSystem:setSpread(5)
end

function love.update(dt)
    particleSystem:update(dt)
end

function love.draw()
    love.graphics.draw(particleSystem, 100, 100)
end
