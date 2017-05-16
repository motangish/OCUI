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
    canvas.currSymbol = " "
end

local function eraserFunc()
    disableTools()
    eraserButton.args.active = true
    ui.draw(bar)
    canvas.currSymbol = -1
end

local function colorFunc()

end

local function toggleFileButton()
    fileButton:flash()
end

local function toggleEditButton()
    editButton:flash()
end

local function setLineDraw()
    tool = "line"
    canvas.drawing = false
end

local function touch(obj, x, y)
    if obj.id == ui.ID.CANVAS then
        if tool == "line" then
            firstX, firstY = x, y
        end
    end
end

local function drag(obj, x, y)
    if obj.id == ui.ID.CANVAS then
        if tool == "line" then
            secondX, secondY = x, y
            canvas:draw()
            buffer.new:drawLine(firstX, firstY, secondX, secondY, " ", canvas.currBColor, canvas.currTColor)
            buffer.draw()
        end
    end
end

local function drop(obj, x, y)
    if obj.id == ui.ID.CANVAS then
        if tool ~= "brush" and tool ~= "eraser" then
            while true do
                local e = {event.pull()}
                if e[1] == "key_down" and e[4] == 0x1C then
                    if tool == "line" then
                        canvas.image:drawLine(firstX, firstY + canvas.y - 2, secondX, secondY + canvas.y - 2, " ", canvas.currBColor, canvas.currTColor)
                        break
                    end
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
    editCM = ui.contextMenu(fileButton.x + fileButton.width + 1, 2, 0xDCDCDC, 0, true, {closing=toggleEditButton, alpha=0.1})
    editCM:addObj("Линия", setLineDraw)
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