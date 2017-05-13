local buffer = require("IBUFFER")
local image = require("IMAGE")
local color = require("COLOR")
local event = require("event")
local unicode = require("unicode")
local kb = require("keyboard")
local gpu = require("component").gpu

local ui = {
	eventHandling=false,
	ID = {
		BOX  			  = 1,
		STANDART_BUTTON   = 2,
		BEAUTIFUL_BUTTON  = 3,
		STANDART_TEXTBOX  = 4,
		BEAUTIFUL_TEXTBOX = 5,
		STANDART_CHECKBOX = 6,
		CONTEXT_MENU      = 7,
		SCROLLBAR         = 8,
		IMAGE             = 9,
		CANVAS            = 10
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
		color=aColor, args=args, ssid=ui.ID.BOX, draw=drawBox, addObj=addObject
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
		buffer.fillBlend(obj.globalX, obj.globalY, obj.width, obj.height, bColor, obj.args.alpha, false)
	else
		buffer.fill(obj.globalX, obj.globalY, obj.width, obj.height, symbol, bColor, nil, false)
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
		bColor=bColor, tColor=tColor, text=text, args=args, id=ui.ID.STANDART_BUTTON, draw=drawStandartButton, flash=flashButton, addObj=addObject
	})
end

--  BEAUTIFUL BUTTON  ------------------------------------------------------------------------------------
local function drawBeautifulButton(obj)
	local bColor, tColor = obj.bColor, obj.tColor
	if obj.args.symbol then symbol = obj.args.symbol end
	if obj.args.active then
		bColor = obj.tColor
		tColor = obj.bColor
	end
	if obj.args.alpha then
		buffer.fillBlend(obj.globalX, obj.globalY, obj.width, obj.height, bColor, obj.args.alpha, false)
	else
		buffer.fill(obj.globalX, obj.globalY, obj.width, obj.height, " ", bColor, nil, false)
	end
	local up = "┌" .. string.rep("─", obj.width - 2) .. "┐"
	local down = "└" .. string.rep("─", obj.width - 2) .. "┘"
	local x2, y = obj.globalX + obj.width - 1, obj.globalY
	buffer.drawText(obj.globalX, y, nil, tColor, up)
	y = y + 1
	for i = 1, obj.height - 2 do
		buffer.drawText(obj.globalX, y, nil, tColor, "│")
		buffer.drawText(x2, y, nil, tColor, "│")
		y = y + 1
	end
	buffer.drawText(obj.globalX, y, nil, tColor, down)
    buffer.drawText(obj.globalX + obj.width / 2 - unicode.len(obj.text) / 2, math.floor(obj.globalY + obj.height / 2), nil, tColor, obj.text)
end

function ui.beautifulButton(x, y, width, height, bColor, tColor, text, args)
	return checkProperties(x, y, width, height, {
		bColor=bColor, tColor=tColor, text=text, args=args, id=ui.ID.BEAUTIFUL_BUTTON, draw=drawBeautifulButton, flash=flashButton, addObj=addObject
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
		bColor=bColor, tColor=tColor, text="", title=title, args=args, id=ui.ID.STANDART_TEXTBOX, draw=drawStandartTextbox, write=writeTextbox, addObj=addObject
	})
end

--  BEAUTIFUL TEXBOX  ------------------------------------------------------------------------------------
local function drawBeautifulTextbox(obj)
	local bColor, tColor = obj.bColor, obj.tColor
	if obj.args.symbol then symbol = obj.args.symbol end
	if obj.args.active then
		bColor = obj.tColor
		tColor = obj.bColor
	end
	if obj.args.alpha then
		buffer.fillBlend(obj.globalX, obj.globalY * 2, obj.width, 4, bColor, nil, obj.args.alpha, true)
	else
		buffer.fill(obj.globalX, obj.globalY * 2, obj.width, 4, " ", bColor, nil, true)
	end
	local length = unicode.len(obj.text)
	if length < obj.width - 2 then
		if length == 0 then 
			buffer.drawText(obj.globalX + 1, obj.globalY + 1, nil, tColor, obj.title)
		else
			buffer.drawText(obj.globalX + 1, obj.globalY + 1, nil, tColor, obj.text)
		end
    else
        buffer.drawText(obj.globalX + 1, obj.globalY + 1, nil, tColor, unicode.sub(obj.text, length - (obj.width - 3), -1))
    end
end

function ui.beautifulTextbox(x, y, width, bColor, tColor, title, args)
	return checkProperties(x, y, width, 3, {
		bColor=bColor, tColor=tColor, text="", title=title, args=args, id=ui.ID.BEAUTIFUL_TEXTBOX, draw=drawBeautifulTextbox, write=writeTextbox, addObj=addObject
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
		bColor=bColor, tColor=tColor, args=args, id=ui.ID.STANDART_CHECKBOX, draw=drawStandartCheckbox, check=checkCheckbox, addObj=addObject
	})
end

--  CONTEXT MENU  ----------------------------------------------------------------------------------------
local function drawContextMenu(obj)
	if obj.showing then
		obj.image = image.crop(obj.globalX, obj.globalY, obj.width, obj.height, buffer.new)
		buffer.fill(obj.globalX, obj.globalY, obj.width, obj.height, " ", obj.bColor)
		for i = 1, #obj.objs do
			buffer.fill(obj.globalX, obj.globalY + i - 1, obj.width, 1, " ", obj.bColor)
			buffer.drawText(obj.globalX + 1, obj.globalY + i - 1, obj.bColor, obj.tColor, obj.objs[i][1])
		end
	end
end

local function doContextMenu(obj)
	local state = true
	obj.showing = true
	drawContextMenu(obj)
	buffer.draw()
	while state do
		local e = {event.pull()}
		if e[1] == "touch" then
			for i = 1, #obj.objs do
				if e[3] >= obj.globalX and e[3] <= obj.globalX + obj.width - 1 and e[4] == obj.globalY + i - 1 then
					buffer.fill(obj.globalX, obj.globalY + i - 1, obj.width, 1, " ", color.invert(obj.bColor))
					buffer.drawText(obj.globalX + 1, obj.globalY + i - 1, nil, color.invert(obj.tColor), obj.objs[i][1])
					buffer.draw()
					os.sleep(0.3)
					buffer.fill(obj.globalX, obj.globalY + i - 1, obj.width, 1, " ", obj.bColor)
					buffer.drawText(obj.globalX + 1, obj.globalY + i - 1, nil, obj.tColor, obj.objs[i][1])
					buffer.draw()
					buffer.drawImage(obj.globalX, obj.globalY, obj.image)
					obj.showing, state = false, false
					buffer.draw()
					if obj.objs[i].func then obj.objs[i].func(obj.objs[i].args) end
					break
				end
			end
		end
	end
end

local function addContextMenuObject(obj, text, func, args)
	local length = unicode.len(text)
	if length + 2 > obj.width then obj.width = length + 2 end
	obj.height = obj.height + 1
	table.insert(obj.objs, {text, func, args})
end

function ui.contextMenu(x, y, bColor, tColor, args)
	return checkProperties(x, y, 1, 0, {
		bColor=bColor, tColor=tColor, args=args, objs={}, id=ui.ID.CONTEXT_MENU, show=doContextMenu, draw=drawContextMenu, addObj=addContextMenuObject
	})
end

--  SCROLLBAR  -------------------------------------------------------------------------------------------
local function drawScrollbar(obj)
	local bColor, tColor = obj.bColor, obj.tColor
	buffer.fill(obj.globalX, obj.globalY, obj.width, obj.height, " ", obj.bColor, obj.bColor)
	buffer.setDrawing(obj.globalX, obj.globalY, obj.width, obj.height)
	ui.drawObject(obj.object, obj.globalX, obj.globalY)
	buffer.setDefaultDrawing()
	local lineHeight = math.floor(obj.height / (obj.object.height / obj.height))
	if lineHeight < 1 then lineHeight = 1 end
	if lineHeight > obj.height then lineHeight = obj.height end
	if not obj.args.hideBar then
		buffer.fill(obj.globalX + obj.width - 1, obj.globalY, 1, obj.height, " ", obj.bColor, nil)
		buffer.fill(obj.globalX + obj.width - 1, obj.globalY + obj.position - 1, 1, lineHeight, " ", obj.tColor, nil)
	end
end

local function scrollbarScroll(obj, position, side)
	if position == -1 then
		if side == 1 then
			obj.position = obj.position - 1
		else
			obj.position = obj.position + 1
		end
	else obj.position = position end
	local lineHeight = math.floor(obj.height / (obj.object.height / obj.height))
	if lineHeight < 1 then lineHeight = 1 end
	if lineHeight > obj.height then lineHeight = obj.height end
	if obj.position + lineHeight - 1 > obj.height then
		obj.position = obj.height - lineHeight + 1
	elseif obj.position < 1 then
		obj.position = 1
	end
	obj.object.y = 1 - math.floor((obj.position - 1) * (obj.object.height / obj.height))
	ui.draw(obj)
end

local function checkScrollbarClick(obj, x, y)
	if x == obj.globalX + obj.width - 1 and y >= obj.globalY + obj.position - 1 and y <= obj.globalY + obj.position + math.floor(obj.height / (obj.object.height / obj.height)) - 2 then
		return true
	end
end

function ui.scrollbar(x, y, width, height, bColor, tColor, object, args)
	return checkProperties(x, y, width, height, {
		bColor=bColor, tColor=tColor, object=object, position=1, args=args, id=ui.ID.SCROLLBAR, scroll=scrollbarScroll, draw=drawScrollbar, addObj=addObject
	})
end

--  IMAGE  -----------------------------------------------------------------------------------------------
local function drawImage(obj)
	buffer.drawImage(obj.globalX, obj.globalY, obj.image)
end

function ui.image(x, y, data)
	return checkProperties(x, y, data.width, data.height, {
		image=data, id=ui.ID.IMAGE, draw=drawImage, addObj=addObject
	})
end

--  CANVAS  ----------------------------------------------------------------------------------------------
local function drawCanvas(obj)
	buffer.drawImage(obj.globalX, obj.globalY, image.replaceNullSymbols(obj.image, "▒"))
end

function ui.canvas(x, y, data)
	return checkProperties(x, y, data.width, data.height, {
		image=data, id=ui.ID.CANVAS, draw=drawCanvas, addObj=addObject
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
			local newClickedObj = clickedObj
			if clickedObj.object then
				local state = 1
				if clickedObj.args.hideBar then state = 0 end
				buffer.setDrawing(clickedObj.globalX, clickedObj.globalY, clickedObj.width - state, clickedObj.height)
				if e[3] < clickedObj.globalX + clickedObj.width - state then
					local newClickedObj2 = ui.checkClick(clickedObj.object, e[3], e[4])
					if newClickedObj2 then
						newClickedObj = newClickedObj2
					end
				end
			end
			-- Checking scrollbar object
			if e[1] == "touch" then
				if newClickedObj.id == ui.ID.STANDART_BUTTON or newClickedObj.id == ui.ID.BEAUTIFUL_BUTTON then newClickedObj:flash() 
				elseif newClickedObj.id == ui.ID.STANDART_TEXTBOX or newClickedObj.id == ui.ID.BEAUTIFUL_TEXTBOX then newClickedObj:write() 
				elseif newClickedObj.id == ui.ID.STANDART_CHECKBOX then newClickedObj:check() 
				elseif newClickedObj.id == ui.ID.CANVAS then
					local x, y = e[3] - newClickedObj.globalX + 1, e[4] - newClickedObj.globalY + 1
					newClickedObj.image:setPixel(x, y, " ", newClickedObj.currBColor)
					gpu.setBackground(newClickedObj.currBColor)
					gpu.set(e[3], e[4], " ")
				end
				if clickedObj.id == ui.ID.SCROLLBAR then
					if checkScrollbarClick(clickedObj, e[3], e[4]) then
						clickedObj.scrolling = true
						clickedObj.scrollingY = e[4] - clickedObj.globalY - clickedObj.position + 2
					end
				end
				if newClickedObj.touch then newClickedObj:touch() end
				if not clickedObj.object and newClickedObj and newClickedObj.touch then newClickedObj:touch() end
				if args.touch then args.touch(e[3], e[4], e[5], e[6]) end
			elseif e[1] == "drag" then
				if clickedObj.id == ui.ID.SCROLLBAR then
					if not checkScrollbarClick(clickedObj, e[3], e[4]) then
						clickedObj.scrolling = false
						clickedObj.scrollingY = nil
					end
					if clickedObj.scrollingY and e[4] - clickedObj.globalY - clickedObj.scrollingY + 2 > 0 then
						clickedObj:scroll(e[4] - clickedObj.globalY - clickedObj.scrollingY + 2)
					end
				end
				if newClickedObj.id == ui.ID.CANVAS then
					local x, y = e[3] - newClickedObj.globalX + 1, e[4] - newClickedObj.globalY + 1
					newClickedObj.image:setPixel(x, y, " ", newClickedObj.currBColor)
					gpu.setBackground(newClickedObj.currBColor)
					gpu.set(e[3], e[4], " ")
				end
				if clickedObj and clickedObj.drag then clickedObj:drag() end
				if args.drag then args.drag(e[3], e[4], e[5], e[6]) end
			elseif e[1] == "drop" then
				if clickedObj.id == ui.ID.SCROLLBAR then
					clickedObj.scrolling = false
					clickedObj.scrollingY = nil
				end
				if newClickedObj.id == ui.ID.CANVAS then
					if clickedObj.object then clickedObj:draw() else newClickedObj:draw() end
				end
			elseif e[1] == "scroll" then
				if clickedObj and clickedObj.scroll then clickedObj:scroll(-1, e[5]) end
				if args.scroll then args.scroll(e[3], e[4], e[5], e[6]) end
			end
			buffer.setDefaultDrawing()
		end
	end
end

return ui