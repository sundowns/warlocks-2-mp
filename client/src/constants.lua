local network_params = {
  LAN = {
    NET_UPDATE_RATE = 2, -- Every 2 ticks
    VARIANCE_POSITION = 10, -- 6 ideal for LAN?
    STABILISATION_TIME = 4, -- Seconds before we can consider RTT accurate
    STABILISATION_RTT = 18
  }
}

Colour = Class {
    init = function(self, red, green, blue, alpha)
        self.r = red
        self.g = green
        self.b = blue
        self.a = alpha
    end;
    get = function(self)
        return self.r, self.g, self.b, self.a
    end
}

local colours = {
    HUD_BACKGROUND = Colour(139, 69, 19, 230),
    HUD_HEALTH = {
        FULL = Colour(0, 255, 34, 255),
        DAMAGED = Colour(144, 255, 0, 255),
        HURT = Colour(255, 234, 0, 255),
        WOUNDED = Colour(255, 162, 0, 255),
        DYING = Colour(255, 0, 0, 255),
        DEAD = Colour(0, 0, 0, 255)
    }
}

return {
  TICKRATE = 0.015625,  --64tick :0.015625 ||| 128tick: 0.0078125
  PLAYER_FRICTION = 150,
  CLIENT_VERSION = "0.0.1",
  PLAYER_BUFFER_LENGTH = 256, -- maintain states for the last x amount of ticks
  PROJECTILE_BUFFER_LENGTH = 64, -- could this being 2 small cause crashes? c how we go
  NET_PARAMS = network_params.LAN,
  COLOURS = colours
}
