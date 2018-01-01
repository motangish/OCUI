local system = require("SYSTEM")
local ui     = require("UI")

local window, cmpBox, cmpPropBox, cmpPropBoxSB, cmpBoxSB, updateButton, closeButton
local fuelAmountPB, fuelTempPB, casingTempPB, fuelAmountL, fuelTempL, casingTempL, energyProdL, fuelConsL, rfL, mbL, enableB, activityB, passTB
local updateCmps, updateCmpProps, updateWindow
local drawWindow = true

local pass = 10 % 3

local currReactor, currName, currAddress, fuelAmount, fuelAmountMax, fuelTempMax, casingTempMax, fuelTemp, casingTemp, fuelConsumed, reactorActive

local function close()
    window = nil
    os.exit()
end

local function displayCmp(args)
    updateCmpProps(args[1], args[2])
end

local function setReactorActivity()
    if tonumber(passTB.text) == pass then
        if reactorActive then
            currReactor.setActive(false)
        else
            currReactor.setActive(true)
        end
    end
end

updateCmps = function()
    cmpBox:cleanObjects()
    local newY, cmps = 2, 0
    local cmpsArr = system.getComponents({"BR Reactor", "BR Turbine"})
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

local function getProps()
    if currName == "BR Reactor" then
        fuelAmountMax, fuelConsumed = currReactor.getFuelAmountMax(), currReactor.getFuelConsumedLastTick()
        fuelAmount, reactorActive = currReactor.getFuelAmount(), currReactor.getActive()
        fuelTemp, casingTemp = currReactor.getFuelTemperature(), currReactor.getCasingTemperature()
        fuelTempMax, casingTempMax = 2000, 2000
    elseif currName == "BR Turbine" then
        fuelAmountMax, fuelConsumed = currReactor.getFluidAmountMax(), currReactor.getBladeEfficiency()
        fuelAmount, reactorActive = currReactor.getInputAmount(), currReactor.getActive()
        fuelTemp, casingTemp = currReactor.getFluidFlowRate(), currReactor.getRotorSpeed()
        fuelTempMax, casingTempMax = currReactor.getFluidFlowRateMax(), 2000
    end
end

updateCmpProps = function(name, address)
    if name and address then
        currName, currAddress = name, address
        currReactor = system.getComponent(currAddress)
        getProps()
        cmpPropBox:cleanObjects()
        cmpPropBox:addObj(ui.label(3, 2, nil, 0xFFFFFF, currName))
        cmpPropBox:addObj(ui.label(3, 3, nil, 0xFFFFFF, currAddress))
        fuelAmountL  = ui.label(3, 5, nil, 0xE1E1E1, "Fuel Amount: " .. math.floor(fuelAmount) .. " mB")
        fuelAmountPB = ui.standartProgressBar(3, 6, 56, 1, 0x666D00, 0xFFB600, fuelAmountMax, fuelAmount)
        fuelTempL    = ui.label(3, 8, nil, 0xE1E1E1, "Fuel Temp:   " .. math.floor(fuelTemp) .. " C")
        fuelTempPB   = ui.standartProgressBar(3, 9, 56, 1, 0x662400, 0xFF6D00, fuelTempMax, fuelTemp)
        casingTempL  = ui.label(3, 11, nil, 0xE1E1E1, "Casing Temp: " .. math.floor(casingTemp) .. " C")
        casingTempPB = ui.standartProgressBar(3, 12, 56, 1, 0x662400, 0xFF6D00, casingTempMax, casingTemp)
        energyProdL  = ui.label(3, 14, nil, 0xE1E1E1, "Energy production : " .. math.floor(currReactor.getEnergyProducedLastTick()))
        fuelConsL    = ui.label(3, 15, nil, 0xE1E1E1, "Fuel consumption  : " .. fuelConsumed)
        rfL          = ui.label(55, 14, nil, 0xF0F0F0, "RF/t")
        mbL          = ui.label(55, 15, nil, 0xF0F0F0, "mB/t")
        activityB    = ui.beautifulButton(3, 17, nil, 3, 0x006600, 0xFFFFFF, "Включить", setReactorActivity)
        passTB       = ui.beautifulTextbox(39, 17, 20, 0xDCDCDC, 0x1C1C1C, "Введите пароль", 20)
        if reactorActive then
            cmpPropBox.color, activityB.bColor, activityB.tColor, activityB.text, activityB.width = 0x006600, 0x006600, 0x660000, "Выключить", 13
        else
            cmpPropBox.color, activityB.bColor, activityB.tColor, activityB.text, activityB.width = 0x660000, 0x660000, 0x006600, "Включить", 12
        end
        cmpPropBox:addObj(rfL)
        cmpPropBox:addObj(mbL)
        cmpPropBox:addObj(fuelAmountL)
        cmpPropBox:addObj(fuelAmountPB)
        cmpPropBox:addObj(fuelTempL)
        cmpPropBox:addObj(fuelTempPB)
        cmpPropBox:addObj(casingTempL)
        cmpPropBox:addObj(casingTempPB)
        cmpPropBox:addObj(energyProdL)
        cmpPropBox:addObj(fuelConsL)
        cmpPropBox:addObj(activityB)
        cmpPropBox:addObj(passTB)
    end
    if currName and currAddress then
        getProps()
        if reactorActive then
            cmpPropBox.color, activityB.bColor, activityB.tColor, activityB.text, activityB.width = 0x006600, 0x006600, 0x660000, "Выключить", 21
        else
            cmpPropBox.color, activityB.bColor, activityB.tColor, activityB.text, activityB.width = 0x660000, 0x660000, 0x006600, "Включить", 20
        end
        if currName == "BR Reactor" then
            activityB.text = activityB.text .. " реактор"
            fuelAmountL:setText("Fuel Amount: " .. math.floor(fuelAmount) .. " mB")
            fuelTempL:setText("Fuel Temp:   " .. math.floor(fuelTemp) .. " C")
            casingTempL:setText("Casing Temp: " .. math.floor(casingTemp) .. " C")
            fuelConsL:setText("Fuel consumption  : " .. fuelConsumed)
            mbL:setText("mB/t")
        elseif currName == "BR Turbine" then
            activityB.text = activityB.text .. " турбину"
            fuelAmountL:setText("Fluid Amount:     " .. math.floor(fuelAmount) .. " mB")
            fuelTempL:setText("Fluid Flow Rate:  " .. math.floor(fuelTemp) .. " mB/t")
            casingTempL:setText("Rotor Speed:      " .. math.floor(casingTemp) .. " RPM")
            fuelConsL:setText("Efficiency        : " .. fuelConsumed)
            mbL:setText("   %")
        end
        fuelAmountPB.max = fuelAmountMax
        fuelAmountPB:setProgress(fuelAmount)
        fuelTempPB:setProgress(fuelTemp)
        casingTempPB:setProgress(casingTemp)
        energyProdL:setText("Energy production : " .. math.floor(currReactor.getEnergyProducedLastTick()))
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

updateWindow()
ui.handleEvents(window, {delay=0.5, whileFunc=onUpdate})