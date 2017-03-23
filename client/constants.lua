local network_params = {
  LAN = {
    NET_UPDATE_RATE = 2, -- Every 2 ticks
    VARIANCE_POSITION = 10, -- 6 ideal for LAN?
    STABILISATION_TIME = 4, -- Seconds before we can consider RTT accurate
    STABILISATION_RTT = 18
  }
}

return {
  TICKRATE = 0.015625,  --64tick :0.015625 ||| 128tick: 0.0078125
  PLAYER_FRICTION = 150,
  CLIENT_VERSION = "0.0.1",
  PLAYER_BUFFER_LENGTH = 256, -- maintain states for the last x amount of ticks
  NET_PARAMS = network_params.LAN
}
