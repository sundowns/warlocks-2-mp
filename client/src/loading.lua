loading = {} -- the error state

function loading:init()
    require("src.stagemanager")
end

function loading:enter(previous, task, data)
  textlog = {}
  love.graphics.setBackgroundColor(120, 60, 80)
  if task == "JOIN_GAME" then
      settings.IP = data.ip
      settings.port = data.port
      settings.username = data.username
      net_initialise()
      send_action_packet("REQUEST_JOIN", {})
      table.insert(textlog, "Joining game")
  end
end

function loading:leave()
  textlog = {}
  reset_colour()
  reset_font()
end

function loading:update(dt)
    network_run()
end

function loading:draw()
  set_font(20, 'debug')
  for i, text in ipairs(textlog) do
      love.graphics.print(text, 50, 10 + i*22)
  end
end
