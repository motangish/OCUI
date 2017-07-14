local shell = require("shell")
local image = require("IMAGE")

local args, options = shell.parse(...)

local bufferedImage = image.load(args[1])
bufferedImage:draw(1, 1)
bufferedImage = nil

while true do
  os.sleep(1)
end
