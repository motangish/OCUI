local ui = require("UI")
local image = require("IMAGE")
local gpu = require("component").gpu

-- MAIN PROGRAM
local width, height, mainImage
local mainBox, bar, cScrollBar, canvas, fileButton, editButton, exitButton, brushButton, eraserButton, colorButton
local currBColor, currTColor = 0, 0xFFFFFF

local function fileFunc()

end

local function editFunc()
	
end

local function exitFunc()
	ui.exit()
end

local function brushFunc()

end

local function eraserFunc()

end

local function colorFunc()
	
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
	brushButton = ui.standartButton(editButton.x + editButton.width + 1, 1, nil, 1, 0xDCDCDC, 0, "Кисть", brushFunc, {toggling=true})
	bar:addObj(brushButton)
	eraserButton = ui.standartButton(brushButton.x + brushButton.width + 1, 1, nil, 1, 0xDCDCDC, 0, "Драялка", eraserFunc, {toggling=true})
	bar:addObj(eraserButton)
	colorButton = ui.standartButton(eraserButton.x + eraserButton.width + 1, 1, nil, 1, 0xDCDCDC, 0, "Цвет", colorFunc)
	bar:addObj(colorButton)
	exitButton = ui.standartButton(width - 8, 1, nil, 1, 0x660000, 0xFFFFFF, "Выйти", exitFunc)
	bar:addObj(exitButton)
	mainBox:addObj(bar)
	-- CANVAS SCROLLBAR
	mainImage = image.new("MAIN_IMAGE", 160, 50)
	mainImage:fill(1, 1, 160, 50, " ", 0xFFFFFF, 0)
	canvas = ui.canvas(1, 1, currBColor, mainImage)
	cScrollBar = ui.scrollbar(1, 2, width, height - 1, 0xFFFFFF, 0, canvas)
	mainBox:addObj(cScrollBar)
end

init()
ui.draw(mainBox)
ui.handleEvents(mainBox)