local comp = require("computer")
local fs = require("filesystem")
local unicode = require("unicode")
local ui = require("UI")
local image = require("IMAGE")
local config = require("CONFIG")

local mainBox, upBar, downBar, shellButton, prevFolderButton, desktopButton, settingsButton, shellCM, deskCM, defaultItemCM, folderCM
local width, height = 160, 50
local deskPath = "/SHELL/DESKTOP/"
local deskItems, initialized = {}, false
local itemNum = 0
local CFG = config.new("/SHELL/CONFIG.cfg")
local clickedItemText, copyText, copyState

-- ICONS
local fileIcon      = image.load("/SHELL/ICONS/FILE.bpix")
local luaIcon       = image.load("/SHELL/ICONS/LUA.bpix")
local folderIcon    = image.load("/SHELL/ICONS/FOLDER.bpix")

local function toggleShellButton()
    shellButton:flash()
end

local function shellFunc()
    shellCM:show()
end

local function exitFunc()
    mainBox, upBar, downBar, shellButton, prevFolderButton, shellCM, deskCM, defaultItemCM, folderCM = nil, nil, nil, nil, nil, nil, nil, nil, nil
    ui.exit()
end

local function createFileFunc(type)
    local mainWindow, fileTB, cancelButton, doneButton
    local function done()
        if type == 0 then
            execute({1, fileTB.text}, 0, 0, 0)
        else
            fs.makeDirectory(deskPath .. fileTB.text)
            update()
        end
    end
    if type == 0 then
        mainWindow = ui.window(nil, nil, 40, 7, 0xDCDCDC, 0xCDCDCD, 0, "Создать файл", true)
        fileTB = ui.beautifulTextbox(2, 2, 38, 0xC3C3C3, 0x1C1C1C, "Введите название файла", nil)
    else
        mainWindow = ui.window(nil, nil, 40, 7, 0xDCDCDC, 0xCDCDCD, 0, "Создать папку", true)
        fileTB = ui.beautifulTextbox(2, 2, 38, 0xC3C3C3, 0x1C1C1C, "Введите название папки", nil)
    end
    cancelButton = ui.beautifulButton(2, 5, 12, 3, 0xDCDCDC, 0x660000, "Отмена", update)
    doneButton = ui.beautifulButton(27, 5, 13, 3, 0xDCDCDC, 0x006600, "Создать", done)
    mainWindow:addObj(fileTB)
    mainWindow:addObj(cancelButton)
    mainWindow:addObj(doneButton)
    ui.draw(mainWindow)
    ui.checkingObject = mainWindow
end

local function renameItemFunc()
    local mainWindow, fileTB, formatTB, dotLabel, cancelButton, doneButton
    local format = ui.getFormatOfFile(deskPath .. clickedItemText)
    if format ~= nil then
        format = string.sub(format, 2, -1)
    else format = "" end
    local function done()
        if formatTB.text == "" then
            fs.rename(deskPath .. clickedItemText, deskPath .. fileTB.text)
        else
            fs.rename(deskPath .. clickedItemText, deskPath .. fileTB.text .. "." .. formatTB.text)
        end
        update()
    end
    if fs.isDirectory(deskPath .. clickedItemText) then
        mainWindow = ui.window(nil, nil, 40, 7, 0xDCDCDC, 0xCDCDCD, 0, "Переименовать папку", true)
        fileTB = ui.beautifulTextbox(2, 2, 29, 0xC3C3C3, 0x1C1C1C, "Введите название папки", nil)
    else
        mainWindow = ui.window(nil, nil, 40, 7, 0xDCDCDC, 0xCDCDCD, 0, "Переименовать файл", true)
        fileTB = ui.beautifulTextbox(2, 2, 29, 0xC3C3C3, 0x1C1C1C, "Введите название файла", nil)
    end
    formatTB = ui.beautifulTextbox(32, 2, 8, 0xC3C3C3, 0x1C1C1C, format, nil)
    formatTB.text = format
    dotLabel = ui.label(31, 3, nil, 0x1C1C1C, ".")
    cancelButton = ui.beautifulButton(2, 5, 12, 3, 0xDCDCDC, 0x660000, "Отмена", update)
    doneButton = ui.beautifulButton(23, 5, 17, 3, 0xDCDCDC, 0x006600, "Переименовать", done)
    mainWindow:addObj(fileTB)
    mainWindow:addObj(formatTB)
    mainWindow:addObj(dotLabel)
    mainWindow:addObj(cancelButton)
    mainWindow:addObj(doneButton)
    ui.draw(mainWindow)
    ui.checkingObject = mainWindow
end

local function editItemFunc()
    os.execute("edit " .. ui.addQuotes(deskPath .. clickedItemText))
    update()
end

local function copyItemFunc()
    copyText = deskPath .. clickedItemText
    copyState = "COPY"
end

local function moveItemFunc()
    copyText = deskPath .. clickedItemText
    copyState = "MOVE"
end

local function pasteItemFunc()
    local fileName = fs.name(copyText)
    if fs.exists(copyText) and not fs.exists(deskPath .. fileName) then
        if copyState == "COPY" then
            fs.copy(copyText, deskPath .. fileName)
        elseif copyState == "MOVE" then
            fs.rename(copyText, deskPath .. fileName)
        end
        copyText, copyState = nil, nil
    end
    update()
end

local function deleteItemFunc()
    local mainWindow, fileLabel, cancelButton, doneButton
    local function done()
        fs.remove(deskPath .. clickedItemText)
        update()
    end
    mainWindow = ui.window(nil, nil, 40, 7, 0xDCDCDC, 0xCDCDCD, 0, "Удалить файл", true)
    fileLabel = ui.label(3, 3, 0x660000, 0xDCDCDC, clickedItemText)
    cancelButton = ui.beautifulButton(2, 5, 12, 3, 0xDCDCDC, 0x660000, "Отмена", update)
    doneButton = ui.beautifulButton(27, 5, 13, 3, 0xDCDCDC, 0x006600, "Удалить", done)
    mainWindow:addObj(fileLabel)
    mainWindow:addObj(cancelButton)
    mainWindow:addObj(doneButton)
    ui.draw(mainWindow)
    ui.checkingObject = mainWindow
end

local function prevFolderFunc()
    deskPath = fs.path(deskPath)
    update()
end

local function toFolder(path)
    deskPath = path
    update()
end

local function addItem(name, type, icon, func, args)
    if name and type and icon and func and args then
        itemNum = itemNum + 1
        if itemNum <= 45 then
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
            deskItems[#deskItems][2].args.touchArgs.clickedItem = #deskItems
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
            local newName = unicode.sub(name, 1, -1)
            addItem(newName, "Fold", folderIcon, execute, {2, newName})
        else
            if format == ".lua" then
                addItem(name, "L", luaIcon, execute, {3, fileName})
            else
                addItem(name, "F", fileIcon, execute, {1, fileName})
            end
        end
    end
end

local function touch(obj, x, y, button)
    if obj == mainBox and button == 1 then
        deskCM.globalX, deskCM.globalY = x, y
        deskCM:show()
    end
end

local function init()
    itemNum = 0
    ui.initialize(not initialized)
    mainBox = ui.box(1, 1, width, height, 0xC3C3C3)
    upBar = ui.box(1, 1, width, 1, 0x969696)
    downBar = ui.box(1, height, width, 1, 0x969696)
    shellButton = ui.standartButton(3, 1, nil, 1, 0xDCDCDC, 0, "SHELL", shellFunc, {toggling=true})
    downBar:addObj(shellButton)
    prevFolderButton = ui.standartButton(12, 1, nil, 1, 0xDCDCDC, 0, "<─", prevFolderFunc)
    downBar:addObj(prevFolderButton)
    desktopButton = ui.standartButton(17, 1, nil, 1, 0xDCDCDC, 0, "DESKTOP", toFolder, {touchArgs="/SHELL/DESKTOP/"})
    downBar:addObj(desktopButton)
    settingsButton = ui.standartButton(width - 12, 1, nil, 1, 0xDCDCDC, 0, "Настройки", settingsButton)
    downBar:addObj(settingsButton)
    shellCM = ui.contextMenu(3, -2, 0xDCDCDC, 0, false, {closing=toggleShellButton, alpha=0.3})
    shellCM:addObj("Выйти в SHELL", exitFunc)
    shellCM:addObj("Перезагрузить", comp.shutdown, true)
    shellCM:addObj("Выключить", comp.shutdown)
    downBar:addObj(shellCM)
    deskCM = ui.contextMenu(1, 1, 0xDCDCDC, 0, true, {alpha=0.3})
    deskCM:addObj("Создать файл", createFileFunc, 0)
    deskCM:addObj("Создать папку", createFileFunc, 1)
    deskCM:addObj("Обновить", update)
    deskCM:addObj(-1)
    deskCM:addObj("Убрать обои", comp.shutdown)
    if copyText ~= nil then
        deskCM:addObj(-1)
        deskCM:addObj("Вставить", pasteItemFunc)
    end
    defaultItemCM = ui.contextMenu(1, 1, 0xDCDCDC, 0, true, {alpha=0.3})
    defaultItemCM:addObj("Редактировать", editItemFunc)
    defaultItemCM:addObj("Копировать", copyItemFunc)
    defaultItemCM:addObj("Переместить", moveItemFunc)
    defaultItemCM:addObj("Переименовать", renameItemFunc)
    defaultItemCM:addObj("Удалить", deleteItemFunc)
    folderCM = ui.contextMenu(1, 1, 0xDCDCDC, 0, true, {alpha=0.3})
    --folderCM:addObj("Копировать", copyItemFunc)
    --folderCM:addObj("Переместить", moveItemFunc)
    folderCM:addObj("Переименовать", renameItemFunc)
    folderCM:addObj("Удалить", deleteItemFunc)
    mainBox:addObj(upBar)
    mainBox:addObj(downBar)
    reloadItems()
    initialized = true
end

function update()
    init()
    ui.draw(mainBox)
    ui.checkingObject = mainBox
    ui.args = {touch=touch}
end

function execute(args, x, y, button)
    if button == 0 or button == nil then        -- LEFT MOUSE BUTTON
        if args[1] == 1 then            -- DEFAULT FILE
            os.execute("edit " .. ui.addQuotes(deskPath .. args[2]))
        elseif args[1] == 2 then        -- FOLDER
            deskPath = deskPath .. args[2] .. "/"
        elseif args[1] == 3 then        -- LUA
            os.execute(deskPath .. args[2])
        end
        update()
    elseif button == 1 then                     -- RIGHT MOUSE BUTTON
        deskItems[args.clickedItem][2]:toggle()
        clickedItemText = args[2]
        if args[1] == 1 or args[1] == 3 then    -- DEFAULT FILE
            defaultItemCM.globalX, defaultItemCM.globalY = x, y
            defaultItemCM:show()
        elseif args[1] == 2 then                -- FOLDER
            folderCM.globalX, folderCM.globalY = x, y
            folderCM:show()
        end
        deskItems[args.clickedItem][2]:toggle()
    end
end

if not CFG.config then
    CFG.config = {
        backColor = 0xC3C3C3
    }
end
fs.makeDirectory(deskPath)
init()
ui.draw(mainBox)
ui.handleEvents(mainBox, {touch=touch})
