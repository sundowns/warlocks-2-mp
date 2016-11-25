return {
  version = "1.1",
  luaversion = "5.1",
  tiledversion = "0.16.0",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 9,
  height = 9,
  tilewidth = 16,
  tileheight = 16,
  nextobjectid = 1,
  properties = {},
  tilesets = {
    {
      name = "Temple of the Cobra Floor",
      firstgid = 1,
      tilewidth = 16,
      tileheight = 16,
      spacing = 0,
      margin = 0,
      image = "../tilesets/Temple of the Cobra Floor.png",
      imagewidth = 128,
      imageheight = 144,
      tileoffset = {
        x = 0,
        y = 0
      },
      properties = {},
      terrains = {},
      tilecount = 72,
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "Ground",
      x = 0,
      y = 0,
      width = 9,
      height = 9,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 10, 11, 26, 10, 11, 0, 0,
        0, 0, 11, 12, 20, 12, 11, 0, 0,
        0, 0, 26, 28, 18, 28, 26, 0, 0,
        0, 0, 11, 12, 20, 12, 11, 0, 0,
        0, 0, 11, 11, 26, 11, 11, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0
      }
    },
    {
      type = "tilelayer",
      name = "Lava",
      x = 0,
      y = 0,
      width = 9,
      height = 9,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        44, 44, 44, 44, 44, 44, 44, 44, 44,
        44, 41, 3, 3, 3, 3, 3, 42, 44,
        44, 17, 0, 0, 11, 0, 0, 29, 44,
        44, 17, 0, 0, 0, 0, 0, 29, 44,
        44, 17, 11, 0, 0, 0, 11, 29, 44,
        44, 17, 0, 0, 0, 0, 0, 29, 44,
        44, 17, 0, 0, 11, 0, 0, 29, 44,
        44, 49, 35, 35, 35, 35, 35, 50, 44,
        44, 44, 44, 44, 44, 44, 44, 44, 44
      }
    }
  }
}
