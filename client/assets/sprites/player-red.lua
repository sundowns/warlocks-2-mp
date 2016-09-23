--http://www.buildandgun.com/2014/07/animated-sprites-in-love2d.html

return {
  name = "player_red",
  image = "assets/sprites/player-red.png"
  frame_duration = 0.1, --  Temp
  sprite_width = 20, -- Pixels
  sprite_height = 20, -- Pixels
  animations_names = {
      "STAND",
      "DASH",
      "RUN"
  },
  animations = {
    --love.graphics.newQuad( X, Y, Width, Height, Image_W, Image_H)
    STAND = {
      love.graphics.newQuad( 1, 1, 81, 64, image_w, image_h ),
    },
    DASH = {

    },
    RUN = {

    }
  }
}
