local network_params = {
  LAN = {
    NET_UPDATE_RATE = 4, -- Every 4 ticks
    VARIANCE_POSITION = 10, -- 6 ideal for LAN?
    VARIANCE_VELOCITY = 30
  }
}

local defaults = {
    PLAYER = {
        max_movement_velocity = 130,
        movement_friction = 200,
        base_acceleration = 240,
        acceleration = 240,
        dash_acceleration = 70,
        dash_duration = "0.3", --for some reason bitser hates decimals in tables? (PROBABLY FLOINTING POINT ERROR  U BIG NOOB? ROUND IT?)
        dash_timer = "0.3",
        dash_cancellable_after = "0.1", --after timer is 0.7, so after 0.3seconds
        width = 20,
	  	height = 22,
    },
    FIREBALL = {
        speed = 80
    }
}

return {
  TICKRATE = 0.015625, -- 64 tick: 0.015625 ||| 128tick: 0.0078125
  MAX_CLIENTS = 5,
  CLIENT_TIMEOUT = 10, -- seconds
  NET_PARAMS = network_params.LAN,
  DEFAULTS = defaults
}
