STI = require 'libs/sti'
local stage_file = nil
local stage = nil
local STAGE_WIDTH = 48
local STAGE_HEIGHT = 48

function load_stage(filename)
  if not love.filesystem.exists("assets/maps/"..filename) then
    GamestateManager.switch(error, "Failed to load map ", "File not found: "..filename)
  end
  stage_file = filename
  stage = STI.new("assets/maps/"..stage_file)
  if pcall(STI.new, "assets/maps/"..stage_file) then
    stage = STI.new("assets/maps/"..stage_file)
    stage:resize(STAGE_WIDTH, STAGE_HEIGHT)
    print("Loaded map succesfully")
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
  dbg("stage (tiles) width: " .. stage.width .. " height: " .. stage.height)
	stage:setDrawRange(x-love.graphics.getWidth()/2, y-love.graphics.getHeight()/2, love.graphics.getWidth(), love.graphics.getHeight())
  stage:drawLayer(stage.layers["Ground"] )
  stage:drawLayer(stage.layers["Lava"] )
  stage:drawLayer(stage.layers["Objects"] )
end
