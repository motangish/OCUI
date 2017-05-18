local ui = require("UI")
local image = require("IMAGE")
local buffer = require("IBUFFER")
local color = require("COLOR")
local event = require("event")
local gpu = require("component").gpu

-- MAIN PROGRAM
local width, height, mainImage
local firstX, firstY, secondX, secondY
local mainBox, bar, cScrollBar, canvas, fileButton, editButton, exitButton, brushButton, eraserButton, colorButton, fileCM, exitCM
local tool = "brush"

local touch

local function disableTools()
    brushButton.args.active = false
    eraserButton.args.active = false
    canvas.drawing = true
end

local function fileFunc()
    fileCM:show()
end

local function editFunc()
    editCM:show()
end

local function exitFunc()
    ui.exit()
end

local function brushFunc()
    disableTools()
    brushButton.args.active = true
    ui.draw(bar)
    tool = "brush"
    canvas.currSymbol = " "
end

local function eraserFunc()
    disableTools()
    eraserButton.args.active = true
    ui.draw(bar)
    tool = "eraser"
    canvas.currSymbol = -1
end

local function colorFunc()
    local colorWindow = ui.window(nil, nil, 64, 36, 0xDCDCDC, 0xCDCDCD, 0, "Выберите цвет", true)
    local palette = image.new("palette", 64, 32)
    local selectedColor = canvas.currBColor
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
        ui.draw(mainBox)
        ui.checkingObject = mainBox
        ui.args.touch = touch
    end
    local function done()
        exitWindow()
        canvas.currBColor = selectedColor
    end
    local function colorTouch(obj, x, y)
        local cObj = ui.checkClick(paletteImgEl, x, y)
        if cObj then
            local symbol, tColor, bColor = gpu.get(x, y)
            selectedColor = bColor
            cTextbox.bColor = selectedColor
            cTextbox.tColor = color.invert(selectedColor)
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
    cExit = ui.beautifulButton(2, 34, 15, 3, 0xDCDCDC, 0x660000, "Назад", exitWindow)
    cDone = ui.beautifulButton(48, 34, 16, 3, 0xDCDCDC, 0x006600, "Готово", done)
    cTextbox = ui.beautifulTextbox(22, 34, 20, selectedColor, color.invert(selectedColor), "0x" .. string.format("%06X", selectedColor), args)
    cTextbox.enter = colorEnter
    colorWindow:addObj(paletteImgEl)
    colorWindow:addObj(cExit)
    colorWindow:addObj(cDone)
    colorWindow:addObj(cTextbox)
    ui.draw(colorWindow)
    ui.checkingObject = colorWindow
    ui.args.touch = colorTouch
end

local function toggleFileButton()
    fileButton:flash()
end

local function toggleEditButton()
    editButton:flash()
end

local function setDrawing(type)
    tool = type
    disableTools()
    canvas.drawing = false
    ui.draw(mainBox)
end

touch = function(obj, x, y)
    if obj.id == ui.ID.CANVAS then
        if tool ~= "brush" and tool ~= "eraser" then
            firstX, firstY = x, y
        end
    end
end

local function drag(obj, x, y)
    if obj.id == ui.ID.CANVAS then
        if tool ~= "brush" and tool ~= "eraser" then
            secondX, secondY = x, y
            canvas:draw()
            if tool == "line" then
                buffer.drawLine(firstX, firstY, secondX, secondY, " ", canvas.currBColor, canvas.currTColor)
            elseif tool == "ellipse" then
                buffer.drawEllipse(firstX, firstY, secondX, secondY, canvas.currBColor)
            elseif tool == "emptySq" or tool == "fillSq" then
                local newX, newY, newW, newH = firstX, firstY, secondX - firstX + 1, secondY - firstY + 1
                if secondX < firstX then
                    newX = secondX
                    newW = firstX - secondX
                end
                if secondY < firstY then
                    newY = secondY
                    newH = firstY - secondY
                end
                if tool == "fillSq" then
                    buffer.fill(newX, newY, newW, newH, " ", canvas.currBColor, canvas.currTColor)
                else
                    buffer.fill(newX, newY, newW, 1, " ", canvas.currBColor, canvas.currTColor)                     -- TOP
                    buffer.fill(newX, newY + 1, 2, newH - 2, " ", canvas.currBColor, canvas.currTColor)             -- LEFT
                    buffer.fill(newX + newW - 2, newY + 1, 2, newH - 2, " ", canvas.currBColor, canvas.currTColor)  -- RIGHT
                    buffer.fill(newX, newY + newH - 1, newW, 1, " ", canvas.currBColor, canvas.currTColor)          -- BOTTOM
                end
            end
            buffer.draw()
        end
    end
end

local function drop(obj, x, y)
    if obj.id == ui.ID.CANVAS then
        if tool ~= "brush" and tool ~= "eraser" then
            while true do
                local e = {event.pull()}
                if e[1] == "touch" then
                    touch(canvas, e[3], e[4])
                    break
                elseif e[1] == "key_down" and e[4] == 0x1C then
                    if tool == "line" then
                        canvas.image:drawLine(firstX, firstY - canvas.globalY + 1, secondX, secondY - canvas.globalY + 1, " ", canvas.currBColor, canvas.currTColor)
                    elseif tool == "ellipse" then
                        canvas.image:drawEllipse(firstX, firstY - canvas.globalY + 1, secondX, secondY - canvas.globalY + 1, canvas.currBColor)
                    elseif tool == "emptySq" or tool == "fillSq" then
                        local newX, newY, newW, newH = firstX, firstY, secondX - firstX + 1, secondY - firstY + 1
                        if secondX < firstX then
                            newX = secondX
                            newW = firstX - secondX
                        end
                        if secondY < firstY then
                            newY = secondY
                            newH = firstY - secondY
                        end
                        if tool == "fillSq" then
                            canvas.image:fill(newX, newY - canvas.globalY + 1, newW, newH, " ", canvas.currBColor, canvas.currTColor)
                        else
                            canvas.image:fill(newX, newY - canvas.globalY + 1, newW, 1, " ", canvas.currBColor, canvas.currTColor)                  -- TOP
                            canvas.image:fill(newX, newY - canvas.globalY + 2, 2, newH - 2, " ", canvas.currBColor, canvas.currTColor)              -- LEFT
                            canvas.image:fill(newX + newW - 2, newY - canvas.globalY + 2, 2, newH - 2, " ", canvas.currBColor, canvas.currTColor)   -- RIGHT
                            canvas.image:fill(newX, newY + newH - canvas.globalY, newW, 1, " ", canvas.currBColor, canvas.currTColor)               -- BOTTOM
                        end
                    end
                    break
                end
            end
        end
    end
end

local function init()
    ui.initialize()
    width, height = gpu.getResolution()
    -- MAIN BOX
    mainBox = ui.box(1, 1, width, height, 0xFFFFFF)
    -- BAR
    bar = ui.box(1, 1, width, 1, 0xCDCDCD)
    fileButton = ui.standartButton(3, 1, nil, 1, 0xDCDCDC, 0, "Файл", fileFunc, {toggling=true})
    bar:addObj(fileButton)
    editButton = ui.standartButton(fileButton.x + fileButton.width + 1, 1, nil, 1, 0xDCDCDC, 0, "Редактирование", editFunc, {toggling=true})
    bar:addObj(editButton)
    brushButton = ui.standartButton(editButton.x + editButton.width + 1, 1, nil, 1, 0xDCDCDC, 0, "Кисть", brushFunc, {active=true, toggling=true})
    bar:addObj(brushButton)
    eraserButton = ui.standartButton(brushButton.x + brushButton.width + 1, 1, nil, 1, 0xDCDCDC, 0, "Драялка", eraserFunc, {toggling=true})
    bar:addObj(eraserButton)
    colorButton = ui.standartButton(eraserButton.x + eraserButton.width + 1, 1, nil, 1, 0xDCDCDC, 0, "Цвет", colorFunc)
    bar:addObj(colorButton)
    exitButton = ui.standartButton(width - 8, 1, nil, 1, 0x660000, 0xFFFFFF, "Выйти", exitFunc)
    bar:addObj(exitButton)
    fileCM = ui.contextMenu(3, 2, 0xDCDCDC, 0, true, {closing=toggleFileButton, alpha=0.1})
    fileCM:addObj("Новый")
    fileCM:addObj("Открыть")
    fileCM:addObj("Сохранить")
    bar:addObj(fileCM)
    editCM = ui.contextMenu(fileButton.x + fileButton.width + 1, 2, 0xDCDCDC, 0, true, {width=16, closing=toggleEditButton, alpha=0.1})
    editCM:addObj("Линия", setDrawing, "line")
    editCM:addObj("Эллипс", setDrawing, "ellipse")
    editCM:addObj("Пустой прямоугольник", setDrawing, "emptySq")
    editCM:addObj("Прямоугольник", setDrawing, "fillSq")
    bar:addObj(editCM)
    mainBox:addObj(bar)
    -- CANVAS SCROLLBAR
    mainImage = image.new("MAIN_IMAGE", 160, 50)
    mainImage:fill(1, 1, 160, 50, " ", 0xFFFFFF, 0)
    canvas = ui.canvas(1, 1, 0, 0xFFFFFF, " ", mainImage)
    cScrollBar = ui.scrollbar(1, 2, width, height - 1, 0xFFFFFF, 0, canvas)
    mainBox:addObj(cScrollBar)
end

init()
ui.draw(mainBox)
ui.handleEvents(mainBox, {touch=touch, drag=drag, drop=drop})