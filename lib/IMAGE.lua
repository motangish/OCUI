local color = require("COLOR")
local sr = require("serialization")
local unicode = require("unicode")
local cmp = require("component")
local comp = require("computer")
local gpu = cmp.gpu

local image = {}
image.__index = image

local function floor(number)
  local num, subNum = math.modf(number)
  if subNum >= 0.5 then
    return num + 1
  else
    return num
  end
end

local function swap(a, b)
  return b, a
end

function image.XYToIndex(x, y, width)
  return (width * (y - 1) + x) * 3 - 2
end

function image.load(path)
  local file = io.open(path, "r")
  local data = file:read("*a")
  file:close()
  return setmetatable(sr.unserialize(data), image)
end

function image.screenshot()
  local width, height = gpu.getResolution()
  local screenshot = image.new("screenshot", width, height)
  local index
  for h = 1, height do
    for w = 1, width do
      index = image.XYToIndex(w, h, width)
      local symbol, tColor, bColor = gpu.get(w, h)
      screenshot.data[index]     = symbol
      screenshot.data[index + 1] = color.to8Bit(bColor)
      screenshot.data[index + 2] = color.to8Bit(tColor)
    end
  end
  return screenshot
end

function image.crop(x, y, width, height, imageToCrop)
  local cropped = image.new("cropped", width, height)
  for h = 1, height do
    for w = 1, width do
      local index = image.XYToIndex(w, h, width)
      local sindex = image.XYToIndex(x + w - 1, y + h - 1, imageToCrop.width)
      cropped.data[index] = imageToCrop.data[sindex]
      cropped.data[index + 1] = imageToCrop.data[sindex + 1]
      cropped.data[index + 2] = imageToCrop.data[sindex + 2]
    end
  end
  return cropped
end

function image.compress(imageToCompress)
  local elements = {}
  local compressedImage = image.new(imageToCompress.name, imageToCompress.width, imageToCompress.height)
  local currBColor, currTColor, mIndex, index, state
  local lX, lY, lWidth, lData = 0, 0, 0, ""
  local mIndex = 1
  for h = 1, imageToCompress.height do
    for w = 1, imageToCompress.width do
      if not elements[mIndex] and imageToCompress.data[mIndex] ~= -1 then
        currBColor = imageToCompress.data[mIndex + 1]
        currTColor = imageToCompress.data[mIndex + 2]
        lX, lY = w, h
        for x = 1, imageToCompress.width - lX + 1 do
          index = image.XYToIndex(lX + x - 1, h, imageToCompress.width)
          if not elements[index] and imageToCompress.data[index] ~= -1 and imageToCompress.data[index + 1] == currBColor and imageToCompress.data[index + 2] == currTColor then
            lData = lData .. imageToCompress.data[index]
            lWidth = lWidth + 1
          else break end
        end
        for x = 1, lWidth do
          elements[image.XYToIndex(lX + x - 1, lY, imageToCompress.width)] = true
        end
        if currBColor or currTColor then
          if not currBColor then currBColor = -1 end
          if not currTColor then currTColor = -1 end
          if not compressedImage.data[currBColor] then compressedImage.data[currBColor] = {} end
          if not compressedImage.data[currBColor][currTColor] then compressedImage.data[currBColor][currTColor] = {} end
          table.insert(compressedImage.data[currBColor][currTColor], lX)
          table.insert(compressedImage.data[currBColor][currTColor], lY)
          table.insert(compressedImage.data[currBColor][currTColor], lData)
        end
        lX, lY, lWidth, lData = 0, 0, 0, ""
      end
      mIndex = mIndex + 1
    end  
  end
  elements = nil
  compressedImage.compressed = true
  return compressedImage
end

function image.compare(old, new)
  local compared = image.new("compared", old.width, old.height)
  for i = 1, #old.data, 3 do
    if old.data[i] ~= new.data[i] or old.data[i + 1] ~= new.data[i + 1] or old.data[i + 2] ~= new.data[i + 2] then
      table.insert(compared.data, new.data[i])
      table.insert(compared.data, new.data[i + 1])
      table.insert(compared.data, new.data[i + 2])
    else
      table.insert(compared.data, -1)
      table.insert(compared.data, -1)
      table.insert(compared.data, -1)
    end
  end
  return compared
end

function image.new(name, width, height)
  local self = setmetatable({}, image)
  self.name = name
  self.width = width
  self.height = height
  self.data = {}
  self.compressed = false
  return self
end

function image:setPixel(x, y, symbol, bColor, tColor, bit8)
  local index = image.XYToIndex(x, y, self.width)
  if symbol then self.data[index] = symbol end
  if bit8 then
    if bColor then self.data[index + 1] = bColor end
    if tColor then self.data[index + 2] = tColor end
  else
    if bColor then self.data[index + 1] = color.to8Bit(bColor) end
    if tColor then self.data[index + 2] = color.to8Bit(tColor) end
  end
end

function image:setDPixel(x, y, aColor, bit8)
  local index = image.XYToIndex(x, floor(y / 2), self.width)
  local num, subNum = math.modf(y / 2)
  local color8Bit = aColor
  if not bit8 then color8Bit = color.to8Bit(aColor) end
  self.data[index] = "▀"
  if subNum > 0.0 then
    self.data[index + 2] = color8Bit
  else
    if not self.data[index + 2] then
      self.data[index + 2] = self.data[index + 1]
    end
    self.data[index + 1] = color8Bit
  end
end

function image:getPixel(x, y)
  local index = image.XYToIndex(x, y, self.width)
  return self.data[index], color.to24Bit(self.data[index + 1]), color.to24Bit(self.data[index + 2])
end

function image:fill(x, y, width, height, symbol, bColor, tColor, dPixel, bit8)
  local bColor8Bit, tColor8Bit = bColor, tColor
  if not bit8 then
    if bColor then bColor8Bit = color.to8Bit(bColor) end
    if tColor then tColor8Bit = color.to8Bit(tColor) end
  end
  local index
  for h = 1, height do
    for w = 1, width do
      if dPixel then
        self:setDPixel(x + w - 1, y + h - 1, bColor8Bit, true)
      else
        index = image.XYToIndex(x + w - 1, y + h - 1, self.width)
        if symbol then self.data[index] = symbol end
        if bColor8Bit then self.data[index + 1] = bColor8Bit end
        if tColor8Bit then self.data[index + 2] = tColor8Bit end
      end
    end
  end
end

function image:fillBlend(x, y, width, height, aColor, alpha, dPixel)
  local index
  for h = 1, height do
    for w = 1, width do
      index = image.XYToIndex(w + x - 1, h + y - 1, self.width)
      if dPixel then
        local index = image.XYToIndex(x + w - 1, floor((y + h - 1) / 2), self.width)
        local num, subNum = math.modf((y + h - 1) / 2)
        if subNum > 0.0 then
          self.data[index + 1] = color.to8Bit(color.blend(color.to24Bit(self.data[index + 1]), aColor, alpha))
        else
          if not self.data[index + 2] then
            self.data[index + 2] = self.data[index + 1]
          end
          self.data[index + 2] = color.to8Bit(color.blend(color.to24Bit(self.data[index + 2]), aColor, alpha))
        end
      else
        self.data[index + 1] = color.to8Bit(color.blend(color.to24Bit(self.data[index + 1]), aColor, alpha))
        self.data[index + 2] = color.to8Bit(color.blend(color.to24Bit(self.data[index + 2]), aColor, alpha))
      end
    end
  end
end

function image:drawLine(x1, y1, x2, y2, symbol, bColor, tColor, dPixel, bit8)
  local steep = false
  local bColor8Bit = bColor
  local tColor8Bit = tColor
  if not bit8 then
    bColor8Bit = color.to8Bit(bColor)
    if not dPixel then tColor8Bit = color.to8Bit(tColor) end
  end
  if math.abs(x1 - x2) < math.abs(y1 - y2) then
    x1, y1 = swap(x1, y1)
    x2, y2 = swap(x2, y2)
    steep = true
  end
  if (x1 > x2) then
    x1, x2 = swap(x1, x2)
    y1, y2 = swap(y1, y2)
  end
  local dx = x2 - x1
  local dy = y2 - y1
  local derror2 = math.abs(dy) * 2
  local error2 = 0
  local y = y1
  for x = x1, x2, 1 do
    if steep then
      if dPixel then
        self:setDPixel(y, x, bColor8Bit)
      else
        self:setPixel(y, x, symbol, bColor8Bit, tColor8Bit)
      end
    else
      if dPixel then
        self:setDPixel(x, y, bColor8Bit)
      else
        self:setPixel(x, y, symbol, bColor, tColor8Bit)
      end
    end
    error2 = error2 + derror2
    if error2 > dx then
      y = y + (y2 > y1 and 1 or -1)
      error2 = error2 - dx * 2
    end
  end
end

function image:drawCircle(xC, yC, radius, aColor, dPixel, bit8)
  local color8Bit = aColor
  if not bit8 then color8Bit = color.to8Bit(aColor) end
  local function setPixels(x, y)
    if dPixel then
      self:setDPixel(xC + x, yC + y, color8Bit)
      self:setDPixel(xC + x, yC - y, color8Bit)
      self:setDPixel(xC - x, yC + y, color8Bit)
      self:setDPixel(xC - x, yC - y, color8Bit)
    else
      self:setPixel(xC + x, yC + y, " ", color8Bit)
      self:setPixel(xC + x, yC - y, " ", color8Bit)
      self:setPixel(xC - x, yC + y, " ", color8Bit)
      self:setPixel(xC - x, yC - y, " ", color8Bit)
    end
  end
  local x, y = 0, radius
  local delta = 3 - 2 * radius
  while (x < y) do
    setPixels(x, y)
    setPixels(y, x)
    if (delta < 0) then
      delta = delta + (4 * x + 6)
    else 
      delta = delta + (4 * (x - y) + 10)
      y = y - 1
    end
    x = x + 1
  end
  if x == y then setPixels(x, y) end
end

function image:drawEllipse(x, y, nWidth, nHeight, aColor, dPixel, bit8)
  local width, height
  if x > nWidth then
    x, width = swap(x, nWidth)
  else width = nWidth end
  if y > nHeight then
    y, height = swap(y, nHeight)
  else height = nHeight end
  local color8Bit = aColor
  if not bit8 then color8Bit = color.to8Bit(aColor) end
  local function setPixels(centerX, centerY, deltaX, deltaY, color)
    if dPixel then
      self:setDPixel(centerX + deltaX, centerY + deltaY, color8Bit, true)
      self:setDPixel(centerX - deltaX, centerY + deltaY, color8Bit, true)
      self:setDPixel(centerX + deltaX, centerY - deltaY, color8Bit, true)
      self:setDPixel(centerX - deltaX, centerY - deltaY, color8Bit, true)
    else
      self:setPixel(centerX + deltaX, centerY + deltaY, " ", color8Bit, nil, true)
      self:setPixel(centerX - deltaX, centerY + deltaY, " ", color8Bit, nil, true)
      self:setPixel(centerX + deltaX, centerY - deltaY, " ", color8Bit, nil, true)
      self:setPixel(centerX - deltaX, centerY - deltaY, " ", color8Bit, nil, true)
    end
  end
  local centerX = math.floor(x + width / 2)
  local centerY = math.floor(y + height / 2)
  local radiusX = math.floor(width / 2)
  local radiusY = math.floor(height / 2)
  local radiusX2 = radiusX * radiusX
  local radiusY2 = radiusY * radiusY
  local quarter = math.floor(radiusX2 / math.sqrt(radiusX2 + radiusY2))
  for x = 0, quarter do
    local y = radiusY * math.sqrt(1 - x * x / radiusX2)
    setPixels(centerX, centerY, x, math.floor(y), color)
  end
  quarter = math.floor(radiusY2 / math.sqrt(radiusX2 + radiusY2))
  for y = 0, quarter do
    x = radiusX * math.sqrt(1 - y * y / radiusY2)
    setPixels(centerX, centerY, math.floor(x), y, color)
  end
end

function image:drawText(x, y, bColor, tColor, text, bit8)
  local index
  local newBColor, newTColor = bColor, tColor
  if not bit8 then
    if bColor then newBColor = color.to8Bit(bColor) end
    if tColor then newTColor = color.to8Bit(tColor) end
  end
  for i = 1, unicode.len(text) do
    index = image.XYToIndex(x + i - 1, y, self.width)
    self.data[index] = unicode.sub(text, i, i)
    if bColor then self.data[index + 1] = newBColor end
    if tColor then self.data[index + 2] = newTColor end
  end
end

function image:drawImage(x, y, imageToDraw)
  if imageToDraw.compressed then
    for bColor, data1 in pairs(imageToDraw.data) do
      for tColor, data2 in pairs(data1) do
        for i = 1, #data2, 3 do
          self:drawText(x + data2[i] - 1, y + data2[i + 1] - 1, bColor, tColor, data2[i + 2], true)
        end
      end
    end
  else
    self:drawImage(x, y, image.compress(imageToDraw))
  end
end

function image:optimizeTo8Bit()
  for i = 1, #self.data, 3 do
    self.data[i + 1] = color.to8Bit(self.data[i + 1])
    self.data[i + 2] = color.to8Bit(self.data[i + 2])
  end
end

function image:save(path)
  local file = io.open(path, "w")
  file:write(sr.serialize(self))
  file:close()
end

function image:draw(x, y)
  if self.compressed then
    for bColor, data1 in pairs(self.data) do
      if bColor then gpu.setBackground(color.to24Bit(bColor)) end
      for tColor, data2 in pairs(data1) do
        gpu.setForeground(color.to24Bit(tColor))
        for i = 1, #data2, 3 do
          gpu.set(x + data2[i] - 1, y + data2[i + 1] - 1, data2[i + 2])
        end
      end
    end
  else
    self = image.compress(self)
    self:draw(x, y)
  end
end

return image