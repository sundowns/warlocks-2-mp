local img_w = 440
local img_h = 440

return {
    serialization_version = "0.0.1",
    name = "player_orange",
    image = "assets/sprites/player-orange.png",
    frame_duration = 0.1,
    animations_names = {
        "STAND",
        "DASH",
        "RUN"
    },
    animations = {
      STAND = {
        love.graphics.newQuad( 1, 1, 20, 20, img_w, img_h )
      },
      DASH = {
        love.graphics.newQuad( 1, 23, 20, 20, img_w, img_h )
      },
      RUN = {
        love.graphics.newQuad( 1, 45, 20, 20, img_w, img_h )
      }
    }
}
