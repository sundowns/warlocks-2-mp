local network_params = {
  LAN = {
    NET_UPDATE_RATE = 4, -- Every 2 ticks
    VARIANCE_POSITION = 6, -- 5 ideal for LAN?
  }
}

return {
  TICKRATE = 0.015625, -- 64 tick
  MAX_CLIENTS = 5,
  CLIENT_TIMEOUT = 10, -- seconds
  NET_PARAMS = network_params.LAN
}
