local image = require("IMAGE")
local gpu = require("component").gpu

local buffer = {}

function buffer.initialize(width, height)
  local newWidth, newHeight
  if width and height then
    newWidth, newHeight = width, height
  else
    newWidth, newHeight = gpu.getResolution()
  end
  buffer.width = newWidth
  buffer.height = newHeight
  buffer.dHeight = newHeight * 2
  buffer.new = image.new("new", newWidth, newHeight)
  buffer.old = image.new("old", newWidth, newHeight)
  buffer.new:fill(1, 1, newWidth, newHeight, " ", 0x1C1C1C, 0xFFFFFF)
  buffer.old:fill(1, 1, newWidth, newHeight, " ", 0x1C1C1C, 0xFFFFFF)
end

function buffer.setPixel(x, y, symbol, bColor, tColor, bit8)
  if x > 0 and x <= buffer.width and y > 0 and y <= buffer.height then
    buffer.new:setPixel(x, y, symbol, bColor, tColor, bit8)
  end
end

function buffer.setDPixel(x, y, color)
  if x > 0 and x <= buffer.width and y > 0 and y <= buffer.dHeight then
    buffer.new:setDPixel(x, y, color, bit8)
  end
end

function buffer.getPixel(x, y)
  return buffer.new:getPixel(x, y)
end

function buffer.fill(x, y, width, height, symbol, bColor, tColor, dPixel, bit8)
  local newX, newY, newW, newH = x, y, width, height
  if x <= 0 then newX = 1 end
  if y <= 0 then newY = 1 end
  if x + width - 1 > buffer.width then newW = buffer.width - x + 1 end
  if x + height - 1 > buffer.height then newH = buffer.height - y + 1 end
  buffer.new:fill(newX, newY, newW, newH, symbol, bColor, tColor, dPixel, bit8)
end

function buffer.fillBlend(x, y, width, height, aColor, alpha, dPixel)
  local newX, newY, newW, newH = x, y, width, height
  if x <= 0 then newX = 1 end
  if y <= 0 then newY = 1 end
  if x + width - 1 > buffer.width then newW = buffer.width - x + 1 end
  if y + height - 1 > buffer.height then newH = buffer.height - y + 1 end
  buffer.new:fillBlend(newX, newY, newW, newH, aColor, alpha, dPixel)
end

function buffer.drawLine(x1, y1, x2, y2, symbol, bColor, tColor, dPixel, bit8)
  buffer.new:drawLine(x1, y1, x2, y2, symbol, bColor, tColor, dPixel, bit8)
end

function buffer.drawCircle(x, y, radius, aColor, dPixel, bit8)
  buffer.new:drawCircle(x, y, radius, aColor, dPixel, bit8)
end

function buffer.drawEllipse(x, y, width, height, aColor, dPixel, bit8)
  buffer.new:drawEllipse(x, y, width, height, aColor, dPixel, bit8)
end

function buffer.drawText(x, y, bColor, tColor, text)
  buffer.new:drawText(x, y, bColor, tColor, text)
end

function buffer.drawImage(x, y, img)
  buffer.new:drawImage(x, y, img)
end

function buffer.draw()
  local compared = image.new("compared", buffer.old.width, buffer.old.height)
  local iP1, iP2
  for i = 1, #buffer.old.data, 3 do
    iP1, iP2 = i + 1, i + 2
    if buffer.old.data[i] ~= buffer.new.data[i] or buffer.old.data[iP1] ~= buffer.new.data[iP1] or buffer.old.data[iP2] ~= buffer.new.data[iP2] then
      table.insert(compared.data, buffer.new.data[i])
      table.insert(compared.data, buffer.new.data[iP1])
      table.insert(compared.data, buffer.new.data[iP2])
      buffer.old.data[i] = buffer.new.data[i]
      buffer.old.data[iP1] = buffer.new.data[iP1]
      buffer.old.data[iP2] = buffer.new.data[iP2]
    else
      table.insert(compared.data, -1)
      table.insert(compared.data, -1)
      table.insert(compared.data, -1)
    end
  end
  compared:draw(1, 1)
  compared = nil
end

buffer.initialize()

return buffer