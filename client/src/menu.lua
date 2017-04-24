menu = {} -- the error state
local menu_image = nil
local menuUI = nil
local validation_errors = nil

function menu:init()
    validation_errors = suit.new()
    menuUI = suit.new()
    validation_errors.theme = Class.clone(suit.theme)

    function validation_errors.theme.Label(text, opt, x, y, w, h)
        love.graphics.setColor(255, 0, 0)
        love.graphics.print(text, x, y)
        love.graphics.setColor(255, 255, 255)
    end

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
    menuUI.layout:reset(100,100)
    validation_errors.layout:reset(100,250)
    menuUI.layout:push(menuUI.layout:row(100, 45)) -- address
        menuUI.layout:padding(3)
        menuUI:Input(ip, menuUI.layout:col(160,35))
        menuUI:Label("Address", {align = "left"}, menuUI.layout:col(80))
    menuUI.layout:pop()
    menuUI.layout:push(menuUI.layout:row(100,45)) --port
        menuUI.layout:padding(3)
        menuUI:Input(port, menuUI.layout:col(160,35))
        menuUI:Label("Port", {align = "left"}, menuUI.layout:col(80))
    menuUI.layout:pop()
    menuUI.layout:push(menuUI.layout:row(100,45)) --username
        menuUI.layout:padding(3)
        menuUI:Input(username, menuUI.layout:col(160,35))
        menuUI:Label("Player Name", {align = "left"}, menuUI.layout:col(140))
    menuUI.layout:pop()
    if total_form_errors > 0 then
        for k, v in pairs(form_errors) do
          validation_errors:Label(v.msg, {align = "left"}, validation_errors.layout:row(300, 15))
        end
    end

    menuUI.layout:row(100, 200)
    menuUI.layout:push(menuUI.layout:row(100,50))
        menuUI.layout:padding(5, 0)
        if menuUI:Button("Close", menuUI.layout:col(160, 40)).hit then
           love.event.quit()
        end
        if menuUI:Button("Connect", menuUI.layout:col(160, 40)).hit then
            try_connect()
        end
    menuUI.layout:pop()
end

function try_connect()
    validate_field(ip.text, "Address", "Please enter an address")
    validate_field(port.text, "Port", "Please enter a port")
    validate_field(username.text, "Username", "Please enter a player name")
    if total_form_errors == 0 then
        print("username: " ..username.text)
        GamestateManager.switch(loading, "JOIN_GAME", {ip = ip.text, port = port.text, username = username.text})
    end
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
    menuUI:draw()
    validation_errors:draw()
    set_font(32, 'game')
    love.graphics.print("Timbo's Warlox", love.graphics.getWidth()/5, love.graphics.getHeight()/14)
    love.graphics.draw(menu_image, love.graphics.getWidth()*0.75, love.graphics.getHeight()/10, 0, 1.5, 1.5)
    reset_font()
end

function menu:keypressed(key)
    if key == "return" then
        try_connect()
    end
end
