local img_w = 1152
local img_h = 96

return {
    serialization_version = "0.0.1",
    name = "explosion",
    image = "assets/sprites/explosion.png",
    frame_duration = 0.07,
    animations_names = {
        "DEFAULT"
    },
    animations = {
      DEFAULT = {
        love.graphics.newQuad( 0, 0, 96, 96, img_w, img_h ),
        love.graphics.newQuad( 96, 0, 96, 96, img_w, img_h ),
        love.graphics.newQuad( 192, 0, 96, 96, img_w, img_h ),
        love.graphics.newQuad( 288, 0, 96, 96, img_w, img_h ),
        love.graphics.newQuad( 384, 0, 96, 96, img_w, img_h ),
        love.graphics.newQuad( 480, 0, 96, 96, img_w, img_h ),
        love.graphics.newQuad( 576, 0, 96, 96, img_w, img_h ),
        love.graphics.newQuad( 672, 0, 96, 96, img_w, img_h ),
        love.graphics.newQuad( 768, 0, 96, 96, img_w, img_h ),
        love.graphics.newQuad( 864, 0, 96, 96, img_w, img_h ),
        love.graphics.newQuad( 960, 0, 96, 96, img_w, img_h ),
        love.graphics.newQuad( 1056, 0, 96, 96, img_w, img_h )
      }
    }
}
