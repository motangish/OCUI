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
		STANDART_TEXTBOX = 3,
		STANDART_CHECKBOX = 4,
		SCROLLBAR = 5
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

function ui.checkClick(obj, x, y)
	if x >= obj.globalX and x <= obj.globalX + obj.width - 1 and y >= obj.globalY and y <= obj.globalY + obj.height - 1 then
		for num, object in pairs(obj.objects) do
			local clickedObj = ui.checkClick(object, x, y)
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
local function drawBox(obj, x, y)
	local symbol = " "
	if obj.args.symbol then symbol = obj.args.symbol end
	if obj.args.alpha then
		buffer.fillBlend(obj.globalX, obj.globalY, obj.width, obj.height, obj.color, obj.args.alpha, obj.args.dPixel)
	else
		buffer.fill(obj.globalX, obj.globalY, obj.width, obj.height, symbol, obj.color, nil, obj.args.dPixel)
	end
end

function ui.box(x, y, width, height, aColor, args)
	return checkProperties(x, y, width, height, {
		color=aColor, id=ui.ID.BOX, draw=drawBox, addObj=addObject
	})
end

--  STANDART BUTTON  -------------------------------------------------------------------------------------
local function drawStandartButton(obj)
	local symbol, bColor, tColor = " ", obj.bColor, obj.tColor
	if obj.args.symbol then symbol = obj.args.symbol end
	if obj.args.active then
		bColor = obj.tColor
		tColor = obj.bColor
	end
	if obj.args.alpha then
		buffer.fillBlend(obj.globalX, obj.globalY, obj.width, obj.height, bColor, obj.args.alpha, obj.args.dPixel)
	else
		buffer.fill(obj.globalX, obj.globalY, obj.width, obj.height, symbol, bColor, nil, obj.args.dPixel)
	end
    buffer.drawText(obj.globalX + obj.width / 2 - unicode.len(obj.text) / 2, math.floor(obj.globalY + obj.height / 2), nil, tColor, obj.text)
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
	local symbol, bColor, tColor = " ", obj.bColor, obj.tColor
	if obj.args.symbol then symbol = obj.args.symbol end
	if obj.args.active then
		bColor = obj.tColor
		tColor = obj.bColor
	end
	if obj.args.alpha then
		buffer.fillBlend(obj.globalX, obj.globalY, obj.width, obj.height, bColor, obj.args.alpha, obj.args.dPixel)
	else
		buffer.fill(obj.globalX, obj.globalY, obj.width, obj.height, symbol, bColor, nil, obj.args.dPixel)
	end
	local length = unicode.len(obj.text)
	if length < obj.width then
		if length == 0 then 
			buffer.drawText(obj.globalX, obj.globalY, nil, tColor, obj.title)
		else
			buffer.drawText(obj.globalX, obj.globalY, nil, tColor, obj.text)
		end
    else
        buffer.drawText(obj.globalX, obj.globalY, nil, tColor, unicode.sub(obj.text, length - (obj.width - 1), -1))
    end
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

--  STANDART CHECKBOX  -----------------------------------------------------------------------------------
local function drawStandartCheckbox(obj)
	local bColor, tColor, symbol = obj.bColor, obj.tColor, "X"
	if obj.args.symbol then symbol = obj.args.symbol end
	if obj.args.active then
		bColor = obj.tColor
		tColor = obj.bColor
	end
	if not obj.args.checked then symbol = " " end
	buffer.setPixel(obj.globalX, obj.globalY, symbol, bColor, tColor)
end

local function checkCheckbox(obj, delay)
	obj.args.active = true
	ui.draw(obj)
	os.sleep(delay or 0.3)
	obj.args.active = false
 	if obj.args.checked then obj.args.checked = false else obj.args.checked = true end
	ui.draw(obj)
end

function ui.standartCheckbox(x, y, bColor, tColor, args)
	return checkProperties(x, y, 1, 1, {
		bColor=bColor, tColor=tColor, id=ui.ID.STANDART_CHECKBOX, draw=drawStandartCheckbox, check=checkCheckbox, addObj=addObject
	})
end

--  SCROLLBAR  -------------------------------------------------------------------------------------------
local function drawScrollbar(obj)
	local bColor, tColor = obj.bColor, obj.tColor
	buffer.setDrawing(obj.globalX, obj.globalY, obj.width, obj.height)
	ui.drawObject(obj.object, obj.globalX, obj.globalY)
	buffer.setDefaultDrawing()
	local lineHeight = obj.height / (obj.object.height / obj.height)
	if lineHeight < 1 then lineHeight = 1 end
	buffer.fill(obj.globalX + obj.width - 1, obj.globalY, 1, obj.height, " ", obj.bColor, nil)
	buffer.fill(obj.globalX + obj.width - 1, obj.globalY + obj.position - 1, 1, lineHeight, " ", obj.tColor, nil)
end

local function scrollbarScroll(obj, position, side)
	if position == -1 then
		if side == 1 then
			obj.position = obj.position - 1
		else
			obj.position = obj.position + 1
		end
	else obj.position = position end
	local lineHeight = obj.height / (obj.object.height / obj.height)
	if lineHeight < 1 then lineHeight = 1 end
	if obj.position + lineHeight - 1 > obj.height then
		obj.position = obj.height - lineHeight + 1
	elseif obj.position < 1 then
		obj.position = 1
	end
	obj.object.y = 1 - (obj.position - 1) * (obj.object.height / obj.height)
	ui.draw(obj)
end

function ui.scrollbar(x, y, width, height, bColor, tColor, object, args)
	return checkProperties(x, y, width, height, {
		bColor=bColor, tColor=tColor, object=object, position=1, id=ui.ID.SCROLLBAR, scroll=scrollbarScroll, draw=drawScrollbar, addObj=addObject
	})
end

--  DRAWING  ---------------------------------------------------------------------------------------------
function ui.drawObject(obj, x, y)
	local newX, newY = x, y
	if x or y then newX, newY = x + obj.x - 1, y + obj.y - 1
	else newX, newY = obj.globalX, obj.globalY end
	if obj.args.visible and obj.args.enabled then
		obj.globalX, obj.globalY = newX, newY
		obj:draw(newX, newY)
		if obj.objects then
			for i = 1, #obj.objects do
				if obj.objects[i].args.visible and obj.objects[i].args.enabled then
					ui.drawObject(obj.objects[i], newX, newY)
				end
			end
		end
	end
end

function ui.draw(obj)
	if obj then ui.drawObject(obj) end
	buffer.draw()
end

--  EVENT HANDLING  --------------------------------------------------------------------------------------
function ui.handleEvents(obj, args)
	args = args or {}
	ui.eventHandling = true
	while ui.eventHandling do
		local e = {event.pull()}
		local clickedObj
		if e[3] and e[4] then clickedObj = ui.checkClick(obj, e[3], e[4]) end
		if clickedObj then
			if e[1] == "touch" then
				local newClickedObj = clickedObj
				if clickedObj.object then
					local newClickedObj2 = ui.checkClick(clickedObj.object, e[3], e[4])
					if newClickedObj2 then
						newClickedObj = newClickedObj2
						if newClickedObj2.touch then newClickedObj2:touch() end
					end
				end
				if newClickedObj.id == ui.ID.STANDART_BUTTON then newClickedObj:flash() 
				elseif newClickedObj.id == ui.ID.STANDART_TEXTBOX then newClickedObj:write() 
				elseif newClickedObj.id == ui.ID.STANDART_CHECKBOX then newClickedObj:check() end
				if newClickedObj and newClickedObj.touch then clickedObj:touch() end
				if args.touch then args.touch(e[3], e[4], e[5], e[6]) end
			elseif e[1] == "drag" then
				if clickedObj and clickedObj.drag then clickedObj:drag() end
				if args.drag then args.drag(e[3], e[4], e[5], e[6]) end
			elseif e[1] == "scroll" then
				if clickedObj and clickedObj.scroll then clickedObj:scroll(-1, e[5]) end
				if args.scroll then args.scroll(e[3], e[4], e[5], e[6]) end
			end
		end
	end
end

return ui