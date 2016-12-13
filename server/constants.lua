local network_params = {
  LAN = {
    NET_UPDATE_RATE = 4, -- Every 2 ticks
    VARIANCE_POSITION = 6, -- 5 ideal for LAN?
  }
}

return {
  TICKRATE = 0.0078125, -- 64 tick: 0.015625 ||| 128tick: 0.0078125
  MAX_CLIENTS = 5,
  CLIENT_TIMEOUT = 10, -- seconds
  NET_PARAMS = network_params.LAN
}
