local fs        = require("filesystem")
local event     = require("event")
local image     = require("IMAGE")
local buffer    = require("IBUFFER")
local color     = require("COLOR")
local ui        = require("UI")
local gpu       = require("component").gpu

local system = {}

function system.initialize()
    ui.initialize(false)
end

function system.selectColor(selectedFunc)
    local colorWindow = ui.window(nil, nil, 64, 36, 0xDCDCDC, 0xCDCDCD, 0, "Выберите цвет", true)
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
        buffer.drawImage(colorWindow.globalX, colorWindow.globalY, oldImage)
        ui.checkingObject = checkingObject
        buffer.draw()
    end
    local function done()
        exitWindow()
        selectedFunc(selectedColor)
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
    ui.checkingObject = colorWindow
    ui.draw(colorWindow)
end

function system.error(message, disableExitButton)
    if message then
        local mainWindow, oldImage, cLabel, cExit, cDone
        local checkingArgs, checkingObject = ui.args, ui.checkingObject
        local function done()
            buffer.drawImage(mainWindow.globalX, mainWindow.globalY, oldImage)
            ui.checkingObject, ui.args = checkingObject, checkingArgs
            buffer.draw()
        end
        local function exit()
            done()
        end
        mainWindow = ui.window(nil, nil, 128, 7, 0xDCDCDC, 0xCDCDCD, 0, "Произошла ошибка!", true)
        oldImage = buffer.crop(mainWindow.globalX, mainWindow.globalY, mainWindow.width + 1, mainWindow.height + 1)
        cLabel = ui.label(3, 3, nil, 0x660000, message)
        if not disableExitButton then
            cExit = ui.beautifulButton(2, 5, 15, 3, 0xDCDCDC, 0x660000, "Выход", exit)
            mainWindow:addObj(cExit)
        end
        cDone = ui.beautifulButton(112, 5, 16, 3, 0xDCDCDC, 0x006600, "Продолжить", done)
        mainWindow:addObj(cLabel)
        mainWindow:addObj(cDone)
        ui.draw(mainWindow)
        ui.handleEvents(mainWindow)
    end
end

function system.execute(path, disableExitButton)
    local success, reason = loadfile(path)
    if success then
        local result, err = pcall(success)
        if not result and type(err) == "string" then
            system.error(err, disableExitButton)
        end
    else
        system.error(reason, disableExitButton)
    end
end

function system.print2DArray(arr)
  for i = 1, #arr do
      if arr[i] ~= nil then
          print(arr[i])
      end
  end
end

return system