local ui     = require("UI")
local color  = require("COLOR")
local image  = require("IMAGE")
local buffer = require("IBUFFER")
local gpu    = require("component").gpu

local colorWindow = ui.window(nil, nil, 64, 36, 0xDCDCDC, 0xCDCDCD, 0, "Цветовая палитра", true)
local oldImage = buffer.crop(colorWindow.globalX, colorWindow.globalY, colorWindow.width + 1, colorWindow.height + 1)
local palette = image.new("palette", 64, 32)
local selectedColor = 0xFFFFFF
local checkingObject, args = ui.checkingObject, ui.args
local paletteImgEl, cExit, cDone, cTextbox
local wP, hP
local index = 1

for h = 1, 16 do
    for w = 1, 16 do
        wP, hP = w * 4 - 3, h * 2 - 1
        palette:fill(wP, hP, 4, 2, " ", color.palette[index])
        index = index + 1
    end
end

local function exitWindow()
    colorWindow = nil
    os.exit()
end

local function done()
    exitWindow()
end

local function colorTouch(obj, x, y)
    local cObj = ui.checkClick(paletteImgEl, x, y)
    if cObj then
        local symbol, tColor, bColor = gpu.get(x, y)
        selectedColor = bColor
        cTextbox.bColor = selectedColor
        cTextbox.tColor = color.invert(selectedColor)
        cTextbox.text = "0x" .. string.format("%06X", selectedColor)
        ui.draw(cTextbox)
    end
end
    
local function colorEnter(newColor)
    if tonumber(newColor) then
        selectedColor = tonumber(newColor)
        cTextbox.bColor = selectedColor
        cTextbox.tColor = color.invert(selectedColor)
        ui.draw(cTextbox)
    end
end

paletteImgEl = ui.image(1, 2, palette)
paletteImgEl.touch = colorTouch
cExit = ui.beautifulButton(2, 34, 15, 3, 0xDCDCDC, 0x660000, "Назад", exitWindow)
cDone = ui.beautifulButton(48, 34, 16, 3, 0xDCDCDC, 0x006600, "Готово", done)
cTextbox = ui.beautifulTextbox(22, 34, 20, selectedColor, color.invert(selectedColor), "0x" .. string.format("%06X", selectedColor), 8, args)
cTextbox.enter = colorEnter
colorWindow:addObj(paletteImgEl)
colorWindow:addObj(cExit)
colorWindow:addObj(cDone)
colorWindow:addObj(cTextbox)

ui.draw(colorWindow)
ui.handleEvents(colorWindow)
