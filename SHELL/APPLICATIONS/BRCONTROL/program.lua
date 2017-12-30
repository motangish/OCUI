local system = require("SYSTEM")
local ui     = require("UI")
local cmp    = require("component")

local window, cmpBox, cmpPropBox, cmpPropBoxSB, cmpBoxSB, updateButton, closeButton
local fuelAmountPB, fuelTempPB, casingTempPB, fuelAmountL, fuelTempL, casingTempL, energyProdL, fuelConsL, enableB, activityB
local updateCmps, updateCmpProps, updateWindow
local drawWindow = true

local currReactor, currName, currAddress, fuelAmount, fuelAmoundMax, fuelTemp, casingTemp, reactorActive

local function close()
    window = nil
    os.exit()
end

local function displayCmp(args)
    updateCmpProps(args[1], args[2])
end

local function setReactorActivity()
    if reactorActive then
        currReactor.setActive(false)
    else
        currReactor.setActive(true)
    end
end

updateCmps = function()
    cmpBox:cleanObjects()
    local newY, cmps = 2, 0
    local cmpsArr = system.getComponents({"BR Reactor"})
    for i = 1, #cmpsArr do
        cmpBox:addObj(ui.standartButton(3, newY, 18, 1, 0xCDCDCD, 0x1C1C1C, cmpsArr[i][1], displayCmp, {touchArgs={cmpsArr[i][1], cmpsArr[i][2]}}))
        cmpBox:addObj(ui.label(22, newY, nil, 0x1C1C1C, cmpsArr[i][2]))
        newY, cmps = newY + 2, cmps + 1
    end
    cmpBox.height = cmps * 2 + 1
    if drawWindow then
        ui.draw(window)
        drawWindow = false
    else ui.draw(cmpBoxSB) end
end

updateCmpProps = function(name, address)
    if name and address then
        currName, currAddress = name, address
        currReactor = cmp.proxy(cmp.get(currAddress))
        fuelAmoundMax = currReactor.getFuelAmountMax()
        fuelAmount, reactorActive = currReactor.getFuelAmount(), currReactor.getActive()
        fuelTemp, casingTemp = currReactor.getFuelTemperature(), currReactor.getCasingTemperature()
        cmpPropBox:cleanObjects()
        cmpPropBox:addObj(ui.label(3, 2, nil, 0xFFFFFF, currName))
        cmpPropBox:addObj(ui.label(3, 3, nil, 0xFFFFFF, currAddress))
        fuelAmountL  = ui.label(3, 5, nil, 0xE1E1E1, "Fuel Amount: " .. math.floor(fuelAmount) .. " mB")
        fuelAmountPB = ui.standartProgressBar(3, 6, 56, 1, 0x666D00, 0xFFB600, fuelAmoundMax, fuelAmount)
        fuelTempL    = ui.label(3, 8, nil, 0xE1E1E1, "Fuel Temp:   " .. math.floor(fuelTemp) .. " C")
        fuelTempPB   = ui.standartProgressBar(3, 9, 56, 1, 0x662400, 0xFF6D00, 2000, fuelTemp)
        casingTempL  = ui.label(3, 11, nil, 0xE1E1E1, "Casing Temp: " .. math.floor(casingTemp) .. " C")
        casingTempPB = ui.standartProgressBar(3, 12, 56, 1, 0x662400, 0xFF6D00, 2000, casingTemp)
        energyProdL  = ui.label(3, 14, nil, 0xE1E1E1, "Energy production : " .. math.floor(currReactor.getEnergyProducedLastTick()))
        fuelConsL    = ui.label(3, 15, nil, 0xE1E1E1, "Fuel consumption  : " .. currReactor.getFuelConsumedLastTick())
        activityB    = ui.beautifulButton(3, 17, nil, 3, 0x006600, 0xFFFFFF, "Включить", setReactorActivity)
        if reactorActive then
            cmpPropBox.color, activityB.bColor, activityB.tColor, activityB.text, activityB.width = 0x006600, 0x006600, 0x660000, "Выключить", 13
        else
            cmpPropBox.color, activityB.bColor, activityB.tColor, activityB.text, activityB.width = 0x660000, 0x660000, 0x006600, "Включить", 12
        end
        cmpPropBox:addObj(ui.label(53, 14, nil, 0xF0F0F0, "RF/tic"))
        cmpPropBox:addObj(ui.label(53, 15, nil, 0xF0F0F0, "mB/tic"))
        cmpPropBox:addObj(fuelAmountL)
        cmpPropBox:addObj(fuelAmountPB)
        cmpPropBox:addObj(fuelTempL)
        cmpPropBox:addObj(fuelTempPB)
        cmpPropBox:addObj(casingTempL)
        cmpPropBox:addObj(casingTempPB)
        cmpPropBox:addObj(energyProdL)
        cmpPropBox:addObj(fuelConsL)
        cmpPropBox:addObj(activityB)
    end
    if currName and currAddress then
        fuelAmountMax = currReactor.getFuelAmountMax()
        fuelAmount, reactorActive = currReactor.getFuelAmount(), currReactor.getActive()
        fuelTemp, casingTemp = currReactor.getFuelTemperature(), currReactor.getCasingTemperature()
        if reactorActive then
            cmpPropBox.color, activityB.bColor, activityB.tColor, activityB.text, activityB.width = 0x006600, 0x006600, 0x660000, "Выключить реактор", 21
        else
            cmpPropBox.color, activityB.bColor, activityB.tColor, activityB.text, activityB.width = 0x660000, 0x660000, 0x006600, "Включить реактор", 20
        end
        fuelAmountL:setText("Fuel Amount: " .. math.floor(fuelAmount) .. " mB")
        fuelAmountPB.max = fuelAmountMax
        fuelAmountPB:setProgress(fuelAmount)
        fuelTempL:setText("Fuel Temp:   " .. math.floor(fuelTemp) .. " C")
        fuelTempPB:setProgress(fuelTemp)
        casingTempL:setText("Casing Temp: " .. math.floor(casingTemp) .. " C")
        casingTempPB:setProgress(casingTemp)
        energyProdL:setText("Energy production : " .. math.floor(currReactor.getEnergyProducedLastTick()))
        fuelConsL:setText("Fuel consumption  : " .. currReactor.getFuelConsumedLastTick())
    end
    ui.draw(cmpPropBoxSB)
end

updateWindow = function()
    updateCmps()
    window:addObj(updateButton)
    window:addObj(closeButton)
    window:addObj(cmpBoxSB)
    window:addObj(cmpPropBoxSB)
    ui.draw(window)
end

local function onUpdate()
    updateCmpProps()
end

window       = ui.window(nil, nil, 60, 35, 0xDCDCDC, 0xCDCDCD, 0, "Управление реакторами", true)
updateButton = ui.standartButton(2, 1, nil, 1, 0xCDCDCD, 0x3C3C3C, "Обновить", updateCmps)
closeButton  = ui.standartButton(51, 1, nil, 1, 0xCDCDCD, 0x660000, "Закрыть", close)
cmpBox       = ui.box(0, 0, 55, 100, 0xC3C3C3)
cmpPropBox   = ui.box(0, 0, 60, 29, 0xDCDCDC)
cmpBoxSB     = ui.scrollbar(1, 2, 60, 5, 0xC3C3C3, 0x1C1C1C, cmpBox)
cmpPropBoxSB = ui.scrollbar(1, 7, 60, 29, 0xDCDCDC, 0x1C1C1C, cmpPropBox)

--0x99B680

updateWindow()
ui.handleEvents(window, {delay=0.5, whileFunc=onUpdate})
