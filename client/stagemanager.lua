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
        stage = STI.new("assets/maps/"..stage_file)
        stage:resize(stage.width,  stage.height)
        print("Loaded "..stage_file.." map succesfully")
    else
        GamestateManager.switch(error_screen, "Failed to load map ", "File is incorrect format or corrupt: "..stage_file)
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
  if stage.layers["Objects"] ~= nil then
    stage:drawLayer(stage.layers["Objects"] )
  end
end
