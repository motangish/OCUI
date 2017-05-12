local image = require("IMAGE")
local color = require("COLOR")
local unicode = require("unicode")
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
  buffer.drawX, buffer.drawY, buffer.drawW, buffer.drawH = 1, 1, buffer.width, buffer.height
  buffer.new = image.new("new", newWidth, newHeight)
  buffer.old = image.new("old", newWidth, newHeight)
  buffer.new:fill(1, 1, newWidth, newHeight, " ", 0x1C1C1C, 0xFFFFFF)
  buffer.old:fill(1, 1, newWidth, newHeight, " ", 0x1C1C1C, 0xFFFFFF)
  gpu.setBackground(0x1C1C1C)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, newWidth, newHeight, " ")
end

local function floor(number)
  local num, subNum = math.modf(number)
  if subNum >= 0.5 then
    return num + 1
  else
    return num
  end
end

local function checkPixel(x, y)
  if x >= buffer.drawX and x <= buffer.drawX + buffer.drawW - 1 and y >= buffer.drawY and y <= buffer.drawY + buffer.drawH - 1 then return true end
  return false
end

function buffer.setDrawing(x, y, width, height)
  buffer.drawX, buffer.drawY, buffer.drawW, buffer.drawH = x, y, width, height
end

function buffer.setDefaultDrawing()
  buffer.drawX, buffer.drawY, buffer.drawW, buffer.drawH = 1, 1, buffer.width, buffer.height
end

function buffer.setPixel(x, y, symbol, bColor, tColor, bit8)
  if checkPixel(x, y) then
    buffer.new:setPixel(x, y, symbol, bColor, tColor, bit8)
  end
end

function buffer.setDPixel(x, y, color)
  if checkPixel(x, math.floor(y / 2)) then
    buffer.new:setDPixel(x, y, color, bit8)
  end
end

function buffer.getPixel(x, y)
  return buffer.new:getPixel(x, y)
end

function buffer.fill(x, y, width, height, symbol, bColor, tColor, dPixel, bit8)
  local bColor8Bit, tColor8Bit = bColor, tColor
  if not bit8 then
    if bColor then bColor8Bit = color.to8Bit(bColor) end
    if tColor then tColor8Bit = color.to8Bit(tColor) end
  end
  local index
  for h = 1, height do
    for w = 1, width do
      if dPixel and checkPixel(x + w - 1, floor((y + h - 1) / 2)) then
        buffer.new:setDPixel(x + w - 1, y + h - 1, bColor8Bit, true)
      elseif checkPixel(x + w - 1, y + h - 1) then
        index = image.XYToIndex(x + w - 1, y + h - 1, buffer.new.width)
        if symbol then buffer.new.data[index] = symbol end
        if bColor8Bit then buffer.new.data[index + 1] = bColor8Bit end
        if tColor8Bit then buffer.new.data[index + 2] = tColor8Bit end
      end
    end
  end
end

function buffer.fillBlend(x, y, width, height, aColor, alpha, dPixel)
  local index
  for h = 1, height do
    for w = 1, width do
      local state = false
      if dPixel then state = checkPixel(x + w - 1, floor((y + h - 1) / 2)) else state = checkPixel(x + w - 1, y + h - 1) end
      if state then
        index = image.XYToIndex(x + w - 1, y + h - 1, buffer.new.width)
        if dPixel then
          local index = image.XYToIndex(x + w - 1, floor((y + h - 1) / 2), buffer.new.width)
          local num, subNum = math.modf((y + h - 1) / 2)
          if subNum > 0.0 then
            buffer.new.data[index + 1] = color.to8Bit(color.blend(color.to24Bit(buffer.new.data[index + 1]), aColor, alpha))
          else
            if not buffer.new.data[index + 2] then
              buffer.new.data[index + 2] = buffer.new.data[index + 1]
            end
            buffer.new.data[index + 2] = color.to8Bit(color.blend(color.to24Bit(buffer.new.data[index + 2]), aColor, alpha))
          end
        else
          buffer.new.data[index + 1] = color.to8Bit(color.blend(color.to24Bit(buffer.new.data[index + 1]), aColor, alpha))
          buffer.new.data[index + 2] = color.to8Bit(color.blend(color.to24Bit(buffer.new.data[index + 2]), aColor, alpha))
        end
      end
    end
  end
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

function buffer.drawText(x, y, bColor, tColor, text, bit8)
  local index
  local newBColor, newTColor = bColor, tColor
  if not bit8 then
    if bColor then newBColor = color.to8Bit(bColor) end
    if tColor then newTColor = color.to8Bit(tColor) end
  end
  for i = 1, unicode.len(text) do
    index = image.XYToIndex(x + i - 1, y, buffer.new.width)
    if checkPixel(x + i - 1, y) then
      buffer.new.data[index] = unicode.sub(text, i, i)
      if bColor then buffer.new.data[index + 1] = newBColor end
      if tColor then buffer.new.data[index + 2] = newTColor end
    end
  end
end

function buffer.drawImage(x, y, img)
  if img.compressed then
    for bColor, data1 in pairs(img.data) do
      for tColor, data2 in pairs(data1) do
        for i = 1, #data2, 3 do
          buffer.drawText(x + data2[i] - 1, y + data2[i + 1] - 1, bColor, tColor, data2[i + 2], true)
        end
      end
    end
  else
    buffer.drawImage(x, y, image.compress(img))
  end
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