local ui = require("UI")
local image = require("IMAGE")
local buffer = require("IBUFFER")
local color = require("COLOR")
local event = require("event")
local gpu = require("component").gpu

-- MAIN PROGRAM
local width, height, mainImage
local firstX, firstY, secondX, secondY
local mainBox, bar, cScrollBar, canvas, fileButton, editButton, exitButton, brushButton, eraserButton, fillButton, textButton, bColorButton, tColorButton, toolLabel,
      fileCM, exitCM, textTB
local tool = "brush"

-- CONSTANTS
local toolTypes = {
    ["brush"]="Кисть",
    ["eraser"]="Драялка",
    ["fill"]="Заливка",
    ["text"]="Текст",
    ["line"]="Линия",
    ["ellipse"]="Эллипс",
    ["emptySq"]="Пустой прямоугольник",
    ["fillSq"]="Прямоугольник"
}

local touch

local function disableTools()
    brushButton.args.active = false
    eraserButton.args.active = false
    fillButton.args.active = false
    textButton.args.active = false
    canvas.drawing = true
end

local function fileFunc()
    fileCM:show()
end

local function editFunc()
    editCM:show()
end

local function exitFunc()
    mainBox = nil
    ui.exit()
end

local function brushFunc()
    disableTools()
    brushButton.args.active = true
    tool = "brush"
    toolLabel:setText("Инструмент: " .. toolTypes[tool])
    ui.draw(bar)
    canvas.currSymbol = " "
end

local function eraserFunc()
    disableTools()
    eraserButton.args.active = true
    tool = "eraser"
    toolLabel:setText("Инструмент: " .. toolTypes[tool])
    ui.draw(bar)
    canvas.currSymbol = -1
end

local function fillFunc()
    disableTools()
    fillButton.args.active = true
    tool = "fill"
    toolLabel:setText("Инструмент: " .. toolTypes[tool])
    ui.draw(bar)
    canvas.currSymbol = " "
    canvas.drawing = false
end

local function textFunc()
    disableTools()
    textButton.args.active = true
    tool = "text"
    toolLabel:setText("Инструмент: " .. toolTypes[tool])
    ui.draw(bar)
    canvas.drawing = false
end

local function colorFunc(type)
    local colorWindow = ui.window(nil, nil, 64, 36, 0xDCDCDC, 0xCDCDCD, 0, "Выберите цвет", true)
    local palette = image.new("palette", 64, 32)
    local selectedColor
    if type == "bColor" then selectedColor = canvas.currBColor else selectedColor = canvas.currTColor end
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
        if type == "bColor" then
            bColorButton.bColor = selectedColor
            bColorButton.tColor = color.invert(selectedColor)
        else
            tColorButton.bColor = selectedColor
            tColorButton.tColor = color.invert(selectedColor)
        end
        ui.draw(mainBox)
        ui.checkingObject = mainBox
        ui.args.touch = touch
    end
    local function done()
        exitWindow()
        if type == "bColor" then canvas.currBColor = selectedColor else canvas.currTColor = selectedColor end
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
    cTextbox = ui.beautifulTextbox(22, 34, 20, selectedColor, color.invert(selectedColor), "0x" .. string.format("%06X", selectedColor), 8, args)
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
    toolLabel:setText("Инструмент: " .. toolTypes[tool])
    disableTools()
    canvas.drawing = false
    ui.draw(mainBox)
end

local sColor, dColor, sSymbol, fState
local function fillCheck(x, y)
    if x > 0 and x <= canvas.image.width and y > 0 and y <= canvas.image.height then
        local index = image.XYToIndex(x, y, canvas.image.width)
        if (canvas.image.data[index + 1] == sColor and canvas.image.data[index + 1] ~= dColor) then
            fState = true
            if sSymbol == -1 and canvas.image.data[index] ~= -1 then fState = false end
            if fState then
                canvas.image.data[index] = " "
                canvas.image.data[index + 1] = dColor
                fillCheck(x + 1, y)
                fillCheck(x - 1, y)
                fillCheck(x, y + 1)
                fillCheck(x, y - 1)
            end
        end
    end
end

touch = function(obj, x, y)
    if obj.id == ui.ID.CANVAS then
        if tool == "fill" then
            local index = image.XYToIndex(x, y - canvas.globalY + 1, canvas.image.width)
            sColor = canvas.image.data[index + 1]
            sSymbol = canvas.image.data[index]
            dColor = color.to8Bit(canvas.currBColor)
            fillCheck(x, y - canvas.globalY + 1)
            ui.draw(mainBox)
        elseif tool == "text" then
            local state = not textTB
            if textTB then canvas:removeObj(textTB) end
            textTB = ui.standartTextbox(x - canvas.globalX + 1, y - canvas.globalY + 1, canvas.width - (x - canvas.globalX), 0, 0xFFFFFF, "", canvas.width - (x - canvas.globalX))
            textTB.enter = function(text)
                canvas:removeObj(textTB)
                canvas.image:drawText(x - canvas.globalX + 1, y - canvas.globalY + 1, nil, canvas.currTColor, text)
                ui.draw(mainBox)
            end
            canvas:addObj(textTB)
            ui.draw(mainBox)
        elseif tool ~= "brush" and tool ~= "eraser" then
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
    fillButton = ui.standartButton(eraserButton.x + eraserButton.width + 1, 1, nil, 1, 0xDCDCDC, 0, "Заливка", fillFunc, {toggling=true})
    bar:addObj(fillButton)
    textButton = ui.standartButton(fillButton.x + fillButton.width + 1, 1, nil, 1, 0xDCDCDC, 0, "Текст", textFunc, {toggling=true})
    bar:addObj(textButton)
    bColorButton = ui.standartButton(textButton.x + textButton.width + 2, 1, nil, 1, 0, 0xFFFFFF, " B ", colorFunc, {touchArgs="bColor"})
    bar:addObj(bColorButton)
    tColorButton = ui.standartButton(bColorButton.x + bColorButton.width + 1, 1, nil, 1, 0xFFFFFF, 0, " T ", colorFunc, {touchArgs="tColor"})
    bar:addObj(tColorButton)
    toolLabel = ui.label(tColorButton.x + tColorButton.width + 2, 1, nil, 0, "Инструмент: " .. toolTypes[tool])
    bar:addObj(toolLabel)
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