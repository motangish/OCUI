local buffer = require("IBUFFER")
local color = require("COLOR")
local event = require("event")
local unicode = require("unicode")
local kb = require("keyboard")

local ui = {
	eventHandling=false,
	ID = {
		BOX = 1,
		STANDART_BUTTON = 2,
		STANDART_TEXTBOX = 3
	}
}

function ui.initialize()
	buffer.initialize()
end

local function codeToSymbol(code)
  local symbol
  if code ~= 0 and code ~= 13 and code ~= 8 and code ~= 9 and code ~= 200 and code ~= 208 and code ~= 203 and code ~= 205 and not kb.isControlDown() then
    symbol = unicode.char(code) 
    if kb.isShiftPressed then symbol = unicode.upper(symbol) end
  end
  return symbol
end

local function checkClick(obj, x, y)
	if x >= obj.globalX and x <= obj.globalX + obj.width - 1 and y >= obj.globalY and y <= obj.globalY + obj.height - 1 then 
		for num, object in pairs(obj.objects) do
			local clickedObj = checkClick(object, x, y)
			if clickedObj then return clickedObj end
		end
		return obj
	end
end

local function addObject(toObj, obj)
	obj.globalX, obj.globalY = toObj.globalX + obj.x - 1, toObj.globalY + obj.y - 1
	table.insert(toObj.objects, obj)
end

local function checkProperties(x, y, width, height, props)
	local newProps = props
	newProps.x, newProps.y, newProps.globalX, newProps.globalY, newProps.width, newProps.height, newProps.objects = x, y, x, y, width, height, {}
	if props.args == nil then newProps.args = {} end
	if props.args.visible == nil then newProps.args.visible = true end
	if props.args.enabled == nil then newProps.args.enabled = true end
	if props.args.active == nil then newProps.args.active = false end
	return newProps
end

--  BOX  -------------------------------------------------------------------------------------------------
local function drawBox(obj)
	local newX, newY, symbol = obj.globalX, obj.globalY, " "
	if obj.args.symbol then symbol = obj.args.symbol end
	if obj.args.alpha then
		buffer.fillBlend(newX, newY, obj.width, obj.height, obj.color, obj.args.alpha, obj.args.dPixel)
	else
		buffer.fill(newX, newY, obj.width, obj.height, symbol, obj.color, nil, obj.args.dPixel)
	end
end

function ui.box(x, y, width, height, aColor, args)
	return checkProperties(x, y, width, height, {
		color=aColor, id=ui.ID.BOX, draw=drawBox, addObj=addObject
	})
end

--  STANDART BUTTON  -------------------------------------------------------------------------------------
local function drawStandartButton(obj)
	local newX, newY, symbol, bColor, tColor = obj.globalX, obj.globalY, " ", obj.bColor, obj.tColor
	if obj.args.symbol then symbol = obj.args.symbol end
	if obj.args.active then
		bColor = obj.tColor
		tColor = obj.bColor
	end
	if obj.args.alpha then
		buffer.fillBlend(newX, newY, obj.width, obj.height, bColor, obj.args.alpha, obj.args.dPixel)
	else
		buffer.fill(newX, newY, obj.width, obj.height, symbol, bColor, nil, obj.args.dPixel)
	end
    buffer.drawText(newX + obj.width / 2 - unicode.len(obj.text) / 2, math.floor(newY + obj.height / 2), nil, tColor, obj.text)
end

local function flashButton(obj, delay)
	obj.args.active = true
	ui.draw(obj)
	os.sleep(delay or 0.3)
	obj.args.active = false
	ui.draw(obj)
end

function ui.standartButton(x, y, width, height, bColor, tColor, text, args)
	return checkProperties(x, y, width, height, {
		bColor=bColor, tColor=tColor, text=text, id=ui.ID.STANDART_BUTTON, draw=drawStandartButton, flash=flashButton, addObj=addObject
	})
end

--  STANDART TEXBOX  -------------------------------------------------------------------------------------
local function drawStandartTextbox(obj)
	local newX, newY, symbol, bColor, tColor = obj.globalX, obj.globalY, " ", obj.bColor, obj.tColor
	if obj.args.symbol then symbol = obj.args.symbol end
	if obj.args.active then
		bColor = obj.tColor
		tColor = obj.bColor
	end
	if obj.args.alpha then
		buffer.fillBlend(newX, newY, obj.width, obj.height, bColor, obj.args.alpha, obj.args.dPixel)
	else
		buffer.fill(newX, newY, obj.width, obj.height, symbol, bColor, nil, obj.args.dPixel)
	end
	local length = unicode.len(obj.text)
	if length < obj.width then
		buffer.drawText(newX, newY, nil, tColor, obj.text)
    else
        buffer.drawText(newX, newY, nil, tColor, unicode.sub(obj.text, length - (obj.width - 1), -1))
    end
    --buffer.drawText(newX + obj.width / 2 - unicode.len(obj.text) / 2, math.floor(newY + obj.height / 2), nil, tColor, obj.text)
end

local function writeTextbox(obj)
	obj.args.active = true
	ui.draw(obj)
	while ui.eventHandling do
		local e = {event.pull()}
		local clickedObj
		if e[1] == "touch" then
			obj.args.active = false
			ui.draw(obj)
			break
		elseif e[1] == "key_down" then
			if e[4] == 0x1C then -- ENTER
				obj.args.active = false
				ui.draw(obj)
				break
			elseif e[4] == 0x0E then -- DELETE

				if obj.text ~= "" then obj.text = unicode.sub(obj.text, 1, -2) end
				ui.draw(obj)
			else
				local symbol = codeToSymbol(e[3])
				if symbol then obj.text = obj.text .. symbol end
				ui.draw(obj)
			end
		end
	end
end

function ui.standartTextbox(x, y, width, bColor, tColor, title, args)
	return checkProperties(x, y, width, 1, {
		bColor=bColor, tColor=tColor, text="", title=title, id=ui.ID.STANDART_TEXTBOX, draw=drawStandartTextbox, write=writeTextbox, addObj=addObject
	})
end

--  DRAWING  ---------------------------------------------------------------------------------------------
local function drawObject(obj)
	if obj.args.visible and obj.args.enabled then
		obj:draw(0, 0)
		if obj.objects then
			for i = 1, #obj.objects do
				if obj.objects[i].args.visible and obj.objects[i].args.enabled then
					drawObject(obj.objects[i], obj.objectsX, obj.objectsY)
				end
			end
		end
	end
end

function ui.draw(obj, x, y)
	if obj then drawObject(obj) end
	buffer.draw(x, y, obj.width, obj.height)
end

--  EVENT HANDLING  --------------------------------------------------------------------------------------
function ui.handleEvents(obj, args)
	args = args or {}
	ui.eventHandling = true
	while ui.eventHandling do
		local e = {event.pull()}
		local clickedObj
		if e[3] and e[4] then clickedObj = checkClick(obj, e[3], e[4]) end
		if e[1] == "touch" then
			if clickedObj.id == ui.ID.STANDART_BUTTON then clickedObj:flash() 
			elseif clickedObj.id == ui.ID.STANDART_TEXTBOX then clickedObj:write() end
			if clickedObj and clickedObj.touch then clickedObj.touch() end
			if args.touch then args.touch(e[3], e[4], e[5], e[6]) end
		elseif e[1] == "drag" then
			if clickedObj and clickedObj.drag then clickedObj.drag() end
			if args.drag then args.drag(e[3], e[4], e[5], e[6]) end
		elseif e[1] == "scroll" then
			if clickedObj and clickedObj.scroll then clickedObj.scroll() end
			if args.scroll then args.scroll(e[3], e[4], e[5], e[6]) end
		end
	end
end

return ui