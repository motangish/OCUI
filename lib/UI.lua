local buffer = require("IBUFFER")
local color = require("COLOR")
local event = require("event")
local unicode = require("unicode")

local ui = {
	eventHandling=false,
	ID = {
		BOX = 1,
		STANDART_BUTTON = 2
	}
}

function ui.initialize()
	buffer.initialize()
end

local function checkClick(obj, x, y)
	if x >= obj.x and x <= obj.x + obj.width - 1 and y >= obj.y and y <= obj.y + obj.height - 1 then 
		for num, object in pairs(obj.objects) do
			local clickedObj = checkClick(object, x - object.x + 1, y - object.y + 1)
			if clickedObj then return clickedObj end
		end
		return obj
	end
end

local function addObject(toObj, obj)
	obj.globalX, obj.globalY = toObj.x + obj.x - 1, toObj.y + obj.y - 1
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
	local newX, newY, symbol = obj.globalX, obj.globalY, " "
	if x and y then newX, newY = x + obj.x - 1, y + obj.y - 1 end
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
local function drawStandartButton(obj, x, y)
	local newX, newY, symbol, bColor, tColor = obj.globalX, obj.globalY, " ", obj.bColor, obj.tColor
	if x and y then newX, newY = x + obj.x - 1, y + obj.y - 1 end
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

--  DRAWING  ---------------------------------------------------------------------------------------------
local function drawObject(obj, x, y)
	if obj.args.visible and obj.args.enabled then
		obj:draw(x, y)
		if obj.objects then
			for i = 1, #obj.objects do
				if obj.objects[i].args.visible and obj.objects[i].args.enabled then
					drawObject(obj.objects[i], obj.x, obj.y)
				end
			end
		end
	end
end

function ui.draw(obj, x, y)
	if obj then drawObject(obj, x, y) end
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
			if clickedObj.id == ui.ID.STANDART_BUTTON then clickedObj:flash() end
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