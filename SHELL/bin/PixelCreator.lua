local ui = require("UI")
local gpu = require("component").gpu

-- MAIN PROGRAM
local width, height, currBColor, currTColor
local mainBox, bar, cScrollBar, canvas, fileButton, editButton, exitButton, brushButton, eraserButton, colorButton

local function fileFunc()

end

local function editFunc()
	
end

local function exitFunc()

end

local function brushFunc()

end

local function eraserFunc()

end

local function colorFunc()

end

local function init()
	width, height = gpu.getResolution()
	-- MAIN BOX
	mainBox = ui.box(1, 1, width, height, 0xFFFFFF)
	-- BAR
	bar = ui.box(1, 1, width, 1, 0xCDCDCD)
	fileButton = ui.standartButton(3, 1, nil, 1, 0xDCDCDC, 0, "Файл", fileFunc)
	bar:addObj(fileButton)
	editButton = ui.standartButton(fileButton.x + fileButton.width + 3, 1, nil, 1, 0xDCDCDC, 0, "Редактирование", editFunc)
	bar:addObj(editButton)
	exitButton = ui.standartButton(editButton.x + editButton.width + 3, 1, nil, 1, 0x660000, 0xFFFFFF, "Выйти", exitFunc)
	bar:addObj(exitButton)
	brushButton = ui.standartButton(exitButton.x + exitButton.width + 3, 1, nil, 1, 0xDCDCDC, 0, "Кисть", brushFunc)
	bar:addObj(brushButton)
	eraserButton = ui.standartButton(brushButton.x + brushButton.width + 3, 1, nil, 1, 0xDCDCDC, 0, "Драялка", eraserFunc)
	bar:addObj(eraserButton)
	colorButton = ui.standartButton(eraserButton.x + eraserButton.width + 3, 1, nil, 1, 0xDCDCDC, 0, "Цвет", colorFunc)
	bar:addObj(colorButton)
	mainBox:addObj(bar)
	-- CANVAS SCROLLBAR
	cScrollBar:addObj(canvas)
	mainBox:addObj(cScrollBar)
end