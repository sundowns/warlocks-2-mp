local img_w = 200
local img_h = 200

return {
    serialization_version = "0.0.1",
    name = "fireball",
    image = "assets/sprites/fireball.png",
    frame_duration = 60,
    animations_names = {
        "DEFAULT"
    },
    animations = {
      DEFAULT = {
        love.graphics.newQuad( 0, 0, 14, 19, img_w, img_h )
      }
    }
}
