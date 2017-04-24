STI = require 'libs.sti'
local stage_file = nil
stage = nil

function load_stage(mapname)
    stage_file = mapname
    if not love.filesystem.exists("assets/maps/"..stage_file) then
    GamestateManager.switch(error_screen, "Failed to load map ", "File not found: "..stage_file)
    end
    local ok = false
    if pcall(STI.new, "assets/maps/"..stage_file) then
        local hash = md5.sumhexa(love.filesystem.read("assets/maps/"..stage_file))
        stage = STI.new("assets/maps/"..stage_file)
        stage:resize(stage.width,  stage.height)
        print("Loaded "..stage_file.." map succesfully")
        generate_tile_hitboxes()
        print("Generated tileworld successfully")
        return hash
    else
        GamestateManager.switch(error_screen, "Failed to load map ", "File is incorrect format or corrupt: "..stage_file)
    end
end

function generate_tile_hitboxes()
    if stage.layers["Collidable Objects"] ~= nil then
        local layer = stage.layers["Collidable Objects"]
        for k, object in pairs(layer.objects) do
            object.hitbox = HC.rectangle(object.x, object.y, object.width, object.height)
            object.hitbox.type = "OBJECT"
            object.hitbox.owner = "__WORLD"
            object.hitbox.properties = object.properties
        end
    end
end

function draw_stage()
  if stage == nil then return end

  local x, y = 0, 0
  if user_alive then
    x, y = camera:position()
  end
  stage:setDrawRange(x-love.graphics.getWidth()/2, y-love.graphics.getHeight()/2, love.graphics.getWidth(), love.graphics.getHeight())
  stage:drawLayer(stage.layers["Lava"] )
  stage:drawLayer(stage.layers["Ground 1"] )
  if stage.layers["Ground 2"] ~= nil then
      stage:drawLayer(stage.layers["Ground 2"] )
  end
  if settings.debug and stage.layers["Collidable Objects"] ~= nil then
      stage:drawLayer(stage.layers["Collidable Objects"] )
  end
end

function draw_foreground()
    if stage == nil then return end
    if stage.layers["Foreground"] ~= nil then
        stage:drawLayer(stage.layers["Foreground"])
    end
end
