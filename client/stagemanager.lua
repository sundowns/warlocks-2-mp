STI = require 'libs/sti'
local stage_file = nil
stage = nil

function load_stage(filename)
  if not love.filesystem.exists("assets/maps/"..filename) then
    GamestateManager.switch(error, "Failed to load map ", "File not found: "..filename)
  end
  stage_file = filename
  if pcall(STI.new, "assets/maps/"..stage_file) then
    stage = STI.new("assets/maps/"..stage_file)
    stage:resize(stage.width,  stage.height)
    print("Loaded "..stage_file.." map succesfully")
  else
    print("[ERROR] Failed to load map. " .. stage_file .. " File is incorrect format or corrupt")
  end
end

function draw_stage()
  if stage == nil then return end
  local x, y = 0, 0
  if user_alive then
    x, y = camera:position()
  end
  stage:setDrawRange(x-love.graphics.getWidth()/2, y-love.graphics.getHeight()/2, love.graphics.getWidth(), love.graphics.getHeight())
  stage:drawLayer(stage.layers["Ground"] )
  stage:drawLayer(stage.layers["Lava"] )
  stage:drawLayer(stage.layers["Objects"] )
end
