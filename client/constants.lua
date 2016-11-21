local network_params = {
  LAN = {
    NET_UPDATE_RATE = 2, -- Every 2 ticks
    VARIANCE_POSITION = 5 -- 5 ideal for LAN?
  }
}

return {
  TICKRATE = 0.015625,  --64 tick
  PLAYER_FRICTION = 150,
  CLIENT_VERSION = "0.0.1",
  PLAYER_BUFFER_LENGTH = 256, -- maintain states for the last x amount of ticks
  NET_PARAMS = network_params.LAN
}
