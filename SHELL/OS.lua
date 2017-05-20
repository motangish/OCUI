local comp = require("computer")
local fs = require("filesystem")
local ui = require("UI")
local image = require("IMAGE")

local mainBox, upBar, downBar, shellButton, shellCM
local width, height = 160, 50
local deskPath = "/SHELL/Desktop/"
local deskItems = {}
local itemNum

local function toggleShellButton()
    shellButton:flash()
end

local function shellFunc()
    shellCM:show()
end

local function exitFunc()
    mainBox = nil
    ui.exit()
end

local function addItem(name, type, icon, func, args)
    if name and type and icon and func and args then
        itemNum = itemNum + 1
        if fileNum <= 45 then
            local num, subNum = math.modf(itemNum / 9)
            if subNum > 0 then num = num + 1 else subNum = 0.9 end
            local x, y = math.floor(subNum * 10), num
            if x == 1 then
                x = 8
                if y == 1 then y = 5 else y = 5 + (y - 1) * 8 end
            else
                y = 5 + (y - 1) * 8
                x = 8 + (x - 1) * 17
            end
            local resizedText = ui.resizeText(name, 14)
            table.insert(deskItems, {
                ui.label(x+ui.centerText(resizedText, 14) - 2, y+6, nil, 0, resizedText),
                ui.imagedButton(x, y, icon, func, {touchArgs=args}), type
            })
            mainBox:addObj(deskItems[#deskItems][1])
            mainBox:addObj(deskItems[#deskItems][2])
        end
    end
end

local function reloadItems()
    for fileName in fs.list(deskPath) do
        local fullPath = deskPath .. fileName
        local name = fs.name(fullPath)
        local format = ui.getFormatOfFile(fullPath)
        if fs.isDirectory(fullPath) then

        else
            addItem(name, "F", )
        end
    end
end

local function init()
    ui.initialize()
    mainBox = ui.box(1, 1, width, height, 0xC3C3C3)
    upBar = ui.box(1, 1, width, 1, 0x969696)
    downBar = ui.box(1, height, width, 1, 0x969696)
    shellButton = ui.standartButton(3, 1, nil, 1, 0xDCDCDC, 0, "SHELL", shellFunc, {toggling=true})
    downBar:addObj(shellButton)
    shellCM = ui.contextMenu(3, -2, 0xDCDCDC, 0, false, {closing=toggleShellButton, alpha=0.1})
    shellCM:addObj("Выйти в SHELL", exitFunc)
    shellCM:addObj("Перезагрузить", comp.shutdown, true)
    shellCM:addObj("Выключить", comp.shutdown)
    downBar:addObj(shellCM)
    mainBox:addObj(upBar)
    mainBox:addObj(downBar)
end

init()
ui.draw(mainBox)
ui.handleEvents(mainBox)