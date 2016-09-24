local img_w = 440
local img_h = 440

return {
    serialization_version = "0.0.1",
    name = "player_green",
    image = "assets/sprites/player-green.png",
    frame_duration = 0.025,
    animations_names = {
        "STAND",
        "DASH",
        "RUN",
        "TURN"
    },
    animations = {
      STAND = {
        love.graphics.newQuad( 1, 1, 20, 20, img_w, img_h)
      },
      DASH = {
        love.graphics.newQuad( 1, 23, 20, 20, img_w, img_h)
      },
      RUN = {
        love.graphics.newQuad( 1, 45, 20, 20, img_w, img_h)
      },
      TURN = {
        love.graphics.newQuad( 1, 67, 20, 20, img_w, img_h),
        love.graphics.newQuad( 23, 67, 20, 20, img_w, img_h),
        love.graphics.newQuad( 45, 67, 20, 20, img_w, img_h),
        love.graphics.newQuad( 67, 67, 20, 20, img_w, img_h),
        love.graphics.newQuad( 89, 67, 20, 20, img_w, img_h),
        love.graphics.newQuad( 111, 67, 20, 20, img_w, img_h),
        love.graphics.newQuad( 133, 67, 20, 20, img_w, img_h),
        love.graphics.newQuad( 155, 67, 20, 20, img_w, img_h),
        love.graphics.newQuad( 177, 67, 20, 20, img_w, img_h),
        love.graphics.newQuad( 199, 67, 20, 20, img_w, img_h),
        love.graphics.newQuad( 221, 67, 20, 20, img_w, img_h)
      }
    }
}
