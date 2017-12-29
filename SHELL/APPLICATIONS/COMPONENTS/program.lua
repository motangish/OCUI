local cmp = require("component")
local ui = require("UI")

local window, cmpBox, cmpPropBox, cmpPropBoxSB, cmpBoxSB, updateButton, closeButton
local updateCmps, updateCmpProps, updateWindow
local drawWindow = true

local function close()
    window = nil
    os.exit()
end

local function displayCmp(args)
    updateCmpProps(args[1], args[2])
end

updateCmps = function()
    cmpBox:cleanObjects()
    local newY = 2
    local cmps = 0
    for address, name in cmp.list() do
        local newName = name
        if name == "filesystem" then newName = "File System"
            elseif name == "eeprom" then newName = "Bios"
            elseif name == "computer" then newName = "Computer"
            elseif name == "internet" then newName = "Internet Card"
            elseif name == "gpu" then newName = "Graphics Card"
            elseif name == "modem" then newName = "Modem"
            elseif name == "keyboard" then newName = "Keyboard"
            elseif name == "screen" then newName = "Screen"
            elseif name == "redstone" then newName = "Redstone"
            elseif name == "disk_drive" then newName = "Disk Drive"
            elseif name == "br_reactor" then newName = "BR Reactor"
            elseif name == "br_turbine" then newName = "BR Turbine"
        end
        cmpBox:addObj(ui.standartButton(3, newY, 18, 1, 0xCDCDCD, 0x1C1C1C, newName, displayCmp, {touchArgs={newName, address}}))
        cmpBox:addObj(ui.label(22, newY, nil, 0x1C1C1C, address))
        newY, cmps = newY + 2, cmps + 1
    end
    cmpBox.height = cmps * 2 + 1
    
    if drawWindow then
        ui.draw(window)
        drawWindow = false
    else ui.draw(cmpBoxSB) end
end

updateCmpProps = function(name, address)
    cmpPropBox:cleanObjects()
    cmpPropBox:addObj(ui.label(3, 2, nil, 0, name))
    cmpPropBox:addObj(ui.label(3, 3, nil, 0, address))
    local methodY = 5
    local funcs = 0
    for method, addit in pairs(cmp.methods(address)) do
        cmpPropBox:addObj(ui.label(5, methodY, nil, 0x1C1C1C, method))
        cmpPropBox:addObj(ui.label(50, methodY, nil, 0x1C1C1C, tostring(addit)))
        methodY, funcs = methodY + 1, funcs + 1
    end
    cmpPropBox.height = funcs + 5
    cmpPropBox.y, cmpPropBoxSB.position = 0, 1
    ui.draw(window)
end

updateWindow = function()
    updateCmps()
    window:addObj(updateButton)
    window:addObj(closeButton)
    window:addObj(cmpBoxSB)
    window:addObj(cmpPropBoxSB)
    ui.draw(window)
end

window       = ui.window(nil, nil, 60, 35, 0xDCDCDC, 0xCDCDCD, 0, "Компоненты компьютера", true)
updateButton = ui.standartButton(2, 1, nil, 1, 0xCDCDCD, 0x3C3C3C, "Обновить", updateCmps)
closeButton  = ui.standartButton(51, 1, nil, 1, 0xCDCDCD, 0x660000, "Закрыть", close)
cmpBox       = ui.box(0, 0, 55, 100, 0xC3C3C3)
cmpPropBox   = ui.box(0, 0, 55, 10, 0xDCDCDC)
cmpBoxSB     = ui.scrollbar(1, 2, 60, 17, 0xC3C3C3, 0x1C1C1C, cmpBox)
cmpPropBoxSB = ui.scrollbar(1, 19, 60, 17, 0xDCDCDC, 0x1C1C1C, cmpPropBox)

updateWindow()
ui.handleEvents(window)