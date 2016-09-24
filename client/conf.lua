function love.conf(t)
	t.title = "Warlocks MP Client"
	t.version = "0.10.1"
	t.window.width = 512 --1024
	t.window.height = 384	--768
	t.window.fullscreen = false
 	t.window.borderless = false         -- Remove all border visuals from the window (boolean)
  t.window.resizable = false          -- Let the window be user-resizable (boolean)
	t.window.icon = "assets/misc/logo.png"

	t.console = true --for windows debugging
	t.window.vsync = false
end
