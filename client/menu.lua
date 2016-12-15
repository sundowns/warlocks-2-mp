menu = {} -- the error state
local menu_image = nil
suit = require 'libs.suit'

function menu:init()
    menu_image = love.graphics.newImage("assets/misc/logo.png")
end

function menu:enter(previous, task)
  love.graphics.setBackgroundColor(60, 120, 80)
end

function menu:leave()
  reset_colour()
  reset_font()
end

local ip = {text=settings.IP}
local port = {text=settings.port}
local username = {text=settings.username}
local form_errors = {}
local total_form_errors = 0
function menu:update(dt)
    set_font(16, 'debug')
    suit.layout:reset(100,100)
    suit.layout:push(suit.layout:row(100, 45)) -- address
        suit.layout:padding(3)
        suit.Input(ip, suit.layout:col(160,35))
        suit.Label("Address", {align = "left"}, suit.layout:col(80))
    suit.layout:pop()
    suit.layout:push(suit.layout:row(100,45)) --port
        suit.layout:padding(3)
        suit.Input(port, suit.layout:col(160,35))
        suit.Label("Port", {align = "left"}, suit.layout:col(80))
    suit.layout:pop()
    suit.layout:push(suit.layout:row(100,45)) --username
        suit.layout:padding(3)
        suit.Input(username, suit.layout:col(160,35))
        suit.Label("Player Name", {align = "left"}, suit.layout:col(140))
    suit.layout:pop()
    if total_form_errors > 0 then
      --http://suit.readthedocs.io/en/latest/gettingstarted.html#gui-instances
      --read above link on gui instances to learn how to make error labels separate
      --suit.theme.color.normal.fg = {255,0,0}
        for k, v in pairs(form_errors) do
          suit.Label(v.msg, {align = "left"}, suit.layout:row(300, 15))
        end
      --suit.theme.color.normal.fg = {188,188,188}
    end

    suit.layout:row(100, 200 - total_form_errors*15)
    suit.layout:push(suit.layout:row(100,50))
        suit.layout:padding(5, 0)
        if suit.Button("Close", suit.layout:col(160, 40)).hit then
           love.event.quit()
        end
        if suit.Button("Connect", suit.layout:col(160, 40)).hit then
            validate_field(ip.text, "Address", "Please enter an address")
            validate_field(port.text, "Port", "Please enter a port")
            validate_field(username.text, "Username", "Please enter a player name")
            print("form error count: " .. total_form_errors)
            if total_form_errors == 0 then
                print("username: " ..username.text)
                GamestateManager.switch(loading, "JOIN_GAME", {ip = ip.text, port = port.text, username = username.text})
            end

        end
    suit.layout:pop()
end

function validate_field(value, fieldname, invalid_msg)
    if not value or value == "" or value == " " then
        if form_errors[fieldname] == nil then --already errored
          total_form_errors = total_form_errors + 1;
        end
        form_errors[fieldname] = { val = value, msg = invalid_msg}
      else
        if form_errors[fieldname] ~= nil then
          form_errors[fieldname] = nil
          total_form_errors = total_form_errors - 1;
        end
      end
end

function menu:draw()
    suit.draw()
    reset_font()
    set_font(32, 'game')
    love.graphics.print("Timbo's Warlox", love.graphics.getWidth()/5, love.graphics.getHeight()/14)
    love.graphics.draw(menu_image, love.graphics.getWidth()*0.75, love.graphics.getHeight()/10, 0, 1.5, 1.5)
    reset_font()
end
