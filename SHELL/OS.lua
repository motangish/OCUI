local comp      = require("computer")
local fs        = require("filesystem")
local unicode   = require("unicode")
local ui        = require("UI")
local image     = require("IMAGE")
local config    = require("CONFIG")
local color     = require("COLOR")
local system    = require("SYSTEM")
local inet      = require("IINTERNET")
local file      = require("FILE")
local comp      = require("computer")

_G._UIVERSION = 13

local mainBox, itemsBox, upBar, searchTB, downBar, shellCM, deskCM, defaultItemCM, folderCM, appCM
local width, height = 160, 50
local binPath = "/SHELL/BIN/"
local deskPath = "/SHELL/DESKTOP/"
local initialized, changeBackground = false, false
local itemNum = 0
local searchText = ""
local CFG = config.new("/SHELL/CONFIG.cfg")
local clickedItem, clickedItemText, copyText, copyState, newUIVersion

-- ICONS
local fileIcon      = image.load("/SHELL/ICONS/FILE.bpix")
local luaIcon       = image.load("/SHELL/ICONS/LUA.bpix")
local imageIcon     = image.load("/SHELL/ICONS/IMAGE.bpix")
local folderIcon    = image.load("/SHELL/ICONS/FOLDER.bpix")
local appIcon       = image.load("/SHELL/ICONS/APP.bpix")

local function toggleShellButton()
    downBar.objects[1]:flash()
end

local function shellFunc()
    shellCM:show()
end

local function exitFunc()
    mainBox, itemsBox, upBar, downBar, shellCM, deskCM, defaultItemCM, folderCM = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
    fileIcon, luaIcon, folderIcon, appIcon = nil, nil, nil, nil
    CFG = nil
    ui.exit()
end

local function settingsFunc()
    local mainWindow, backLabel, iconsLabel, imageTB, colorButton, iconsColorButton, pcancelButton, doneButton
    local colorSelectionFor = 0
    local function done()
        CFG.config.backColor = colorButton.bColor
        CFG.config.iconsColor = iconsColorButton.bColor
        if imageTB.text ~= "" then CFG.config.backImage = imageTB.text end
        CFG:save()
        changeBackground = true
        update()
    end
    local function colorSelected(selectedColor)
    	if colorSelectionFor == 0 then
        	colorButton.bColor = selectedColor
        	colorButton.tColor = color.invert(selectedColor)
        	ui.draw(colorButton)
        elseif colorSelectionFor == 1 then
        	iconsColorButton.bColor = selectedColor
        	iconsColorButton.tColor = color.invert(selectedColor)
        	ui.draw(iconsColorButton)
        end
    end
    local function selectColor(num)
    	colorSelectionFor = num
    	system.selectColor(colorSelected)
    end
    mainWindow = ui.window(nil, nil, 40, 12, 0xDCDCDC, 0xCDCDCD, 0, "Настройки", true)
    backLabel = ui.label(3, 3, nil, 0, "Фон")
    imageTB = ui.beautifulTextbox(2, 4, 38, 0xC3C3C3, 0x1C1C1C, "Путь к изображению", nil)
    colorButton = ui.standartButton(2, 7, 38, 2, CFG.config.backColor, 0, "", selectColor, {touchArgs=0})
    iconsColorButton = ui.standartButton(2, 9, 38, 1, CFG.config.iconsColor, color.invert(CFG.config.iconsColor), "Цвет названия значков", selectColor, {touchArgs=1})
    cancelButton = ui.beautifulButton(2, 10, 12, 3, 0xDCDCDC, 0x660000, "Отмена", update)
    doneButton = ui.beautifulButton(27, 10, 13, 3, 0xDCDCDC, 0x006600, "Сохранить", done)
    mainWindow:addObj(backLabel)
    mainWindow:addObj(imageTB)
    mainWindow:addObj(colorButton)
    mainWindow:addObj(iconsColorButton)
    mainWindow:addObj(cancelButton)
    mainWindow:addObj(doneButton)
    ui.draw(mainWindow)
    ui.checkingObject = mainWindow
end

local function createFileFunc(type)
    local mainWindow, fileTB, cancelButton, doneButton
    local function done()
        if type == 0 then
            execute({1, fileTB.text}, 0, 0, 0)
        elseif type == 1 then
            fs.makeDirectory(deskPath .. fileTB.text)
            update()
        elseif type == 2 then
            deskPath = deskPath .. fileTB.text .. ".app/"
            fs.makeDirectory(deskPath)
            appIcon:save(deskPath .. "icon.bpix")
            fs.copy(binPath .. "SAMPLEAPP.lua", deskPath .. "program.lua")
            os.execute("edit " .. ui.addQuotes(deskPath .. "program.lua"))
            update(true)
        end
    end
    if type == 0 then
        mainWindow = ui.window(nil, nil, 40, 7, 0xDCDCDC, 0xCDCDCD, 0, "Создать файл", true)
        fileTB = ui.beautifulTextbox(2, 2, 38, 0xC3C3C3, 0x1C1C1C, "Введите название файла", nil)
    elseif type == 1 then
        mainWindow = ui.window(nil, nil, 40, 7, 0xDCDCDC, 0xCDCDCD, 0, "Создать папку", true)
        fileTB = ui.beautifulTextbox(2, 2, 38, 0xC3C3C3, 0x1C1C1C, "Введите название папки", nil)
    elseif type == 2 then
        mainWindow = ui.window(nil, nil, 40, 7, 0xDCDCDC, 0xCDCDCD, 0, "Создать приложение", true)
        fileTB = ui.beautifulTextbox(2, 2, 38, 0xC3C3C3, 0x1C1C1C, "Введите название приложения", nil)
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
    update(true)
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
    deskCM:removeObj(#deskCM.objs - 1)
    deskCM:removeObj(#deskCM.objs)
    update()
end


local function copyItemFunc()
    if copyState == nil then
        deskCM:addObj(-1)
        deskCM:addObj("Вставить", pasteItemFunc)
    end
    copyText = deskPath .. clickedItemText
    copyState = "COPY"
end

local function moveItemFunc()
    if copyState == nil then
        deskCM:addObj(-1)
        deskCM:addObj("Вставить", pasteItemFunc)
    end
    copyText = deskPath .. clickedItemText
    copyState = "MOVE"
end

local function deleteItemFunc(type)
    local mainWindow, fileLabel, cancelButton, doneButton
    local function done()
        if type == 1 then
            fs.remove(deskPath .. clickedItemText .. ".app")
        else
            fs.remove(deskPath .. clickedItemText)
        end
        update()
    end
    if type == 1 then
        mainWindow = ui.window(nil, nil, 40, 7, 0xDCDCDC, 0xCDCDCD, 0, "Удалить приложение", true)
    elseif fs.isDirectory(deskPath .. clickedItemText) then
        mainWindow = ui.window(nil, nil, 40, 7, 0xDCDCDC, 0xCDCDCD, 0, "Удалить папку", true)
    else
        mainWindow = ui.window(nil, nil, 40, 7, 0xDCDCDC, 0xCDCDCD, 0, "Удалить файл", true)
    end
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
    searchTB.text = ""
    deskPath, searchText = path, ""
    update()
end

local function openAppFolderFunc()
    toFolder(deskPath .. clickedItemText .. ".app/")
end

local function removeWallpaperFunc()
    CFG.config.backImage = nil
    CFG:save()
    changeBackground = true
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
            local newArgs = args
            newArgs.num = itemNum
            itemsBox:addObj(ui.label(x+ui.centerText(resizedText, 14) - 2, y+6, nil, CFG.config.iconsColor, resizedText))
            itemsBox:addObj(ui.imagedButton(x, y, icon, func, {touchArgs=newArgs, disableActive=true}))
        end
    end
end

local function searchEnter(text)
    searchText = text
    update()
end

local function updateSystem()
    inet.download("https://raw.githubusercontent.com/motangish/OCUI/master/ui_installer.lua", "/tmp/ui_installer.lua")
    system.execute("/tmp/ui_installer.lua")
end

local function reloadItems()
    itemsBox:cleanObjects()
    for fileName in fs.list(deskPath) do
        if (searchText ~= "" and string.find(fileName, searchText)) or (searchText == "") then
            local fullPath = deskPath .. fileName
            local name = fs.name(fullPath)
            local format = ui.getFormatOfFile(fullPath)
            if fs.isDirectory(fullPath) then
                if format == ".app" then
                    local newName = unicode.sub(name, 1, -5)
                    local iconPath = fullPath .. "icon.bpix"
                    if fs.exists(iconPath) then
                        addItem(newName, "App", image.load(iconPath), execute, {4, newName})
                    else
                        addItem(newName, "App", appIcon, execute, {4, newName})
                    end
                else
                    local newName = unicode.sub(name, 1, -1)
                    addItem(newName, "Fold", folderIcon, execute, {2, newName})
                end
            else
                if format == ".lua" then
                    addItem(name, "L", luaIcon, execute, {3, fileName})
                elseif format == ".bpix" then
                    addItem(name, "I", imageIcon, execute, {5, fileName})
                else
                    addItem(name, "F", fileIcon, execute, {1, fileName})
                end
            end
        end
    end
end

local function touch(obj, x, y, button)
    if obj == itemsBox and button == 1 then
        deskCM.globalX, deskCM.globalY = x, y
        deskCM:show()
    end
end

local function init()
    local backImageExists = false
    itemNum = 0
    ui.initialize(not initialized)
    if changeBackground or not initialized then
        if CFG.config.backImage and CFG.config.backImage ~= "" and fs.exists(CFG.config.backImage) then
            backImageExists = true
            mainBox = ui.image(1, 1, image.load(CFG.config.backImage))
        else
            mainBox = ui.box(1, 1, width, height, CFG.config.backColor)
        end
    end
    if not initialized or changeBackground then
        itemsBox = ui.box(1, 2, width, height - 2, nil, {hideBox=true})
        upBar = ui.box(1, 1, width, 1, 0x969696)
        searchTB = ui.standartTextbox(3, 1, 30, 0x1C1C1C, 0xFFFFFF, "Поиск...", 100)
        searchTB.enter = searchEnter
        upBar:addObj(searchTB)
        if _G._UIVERSION ~= newUIVersion then
            upBar:addObj(ui.standartButton(width - 11, 1, nil, 1, 0x006600, 0xFFFFFF, "Обновить", updateSystem))
        end
        downBar = ui.box(1, height, width, 1, 0x969696)
        downBar:addObj(ui.standartButton(3, 1, nil, 1, 0xDCDCDC, 0, "SHELL", shellFunc, {toggling=true}))
        downBar:addObj(ui.standartButton(12, 1, nil, 1, 0xDCDCDC, 0, "<─", prevFolderFunc))
        downBar:addObj(ui.standartButton(17, 1, nil, 1, 0xDCDCDC, 0, "Рабочий стол", toFolder, {touchArgs="/SHELL/DESKTOP/"}))
        downBar:addObj(ui.standartButton(32, 1, nil, 1, 0xDCDCDC, 0, "Изображения", toFolder, {touchArgs="/SHELL/PICTURES/"}))
        downBar:addObj(ui.standartButton(width - 12, 1, nil, 1, 0xDCDCDC, 0, "Настройки", settingsFunc))
        shellCM = ui.contextMenu(3, -2, 0xDCDCDC, 0, false, {closing=toggleShellButton, alpha=0.4})
        shellCM:addObj("Выйти в SHELL", exitFunc)
        shellCM:addObj("Перезагрузить", comp.shutdown, true)
        shellCM:addObj("Выключить", comp.shutdown)
        downBar:addObj(shellCM)
        defaultItemCM = ui.contextMenu(1, 1, 0xDCDCDC, 0, true, {alpha=0.4})
        defaultItemCM:addObj("Редактировать", editItemFunc)
        defaultItemCM:addObj("Копировать", copyItemFunc)
        defaultItemCM:addObj("Переместить", moveItemFunc)
        defaultItemCM:addObj("Переименовать", renameItemFunc)
        defaultItemCM:addObj("Удалить", deleteItemFunc)
        folderCM = ui.contextMenu(1, 1, 0xDCDCDC, 0, true, {alpha=0.4})
        folderCM:addObj("Переименовать", renameItemFunc)
        folderCM:addObj("Удалить", deleteItemFunc)
        appCM = ui.contextMenu(1, 1, 0xDCDCDC, 0, true, {alpha=0.4})
        appCM:addObj("Открыть папку", openAppFolderFunc)
        appCM:addObj("Удалить", deleteItemFunc, 1)
        mainBox:addObj(upBar)
        mainBox:addObj(downBar)
        mainBox:addObj(itemsBox)
        deskCM = ui.contextMenu(1, 1, 0xDCDCDC, 0, true, {alpha=0.4})
        deskCM:addObj("Создать файл", createFileFunc, 0)
        deskCM:addObj("Создать папку", createFileFunc, 1)
        deskCM:addObj("Создать приложение", createFileFunc, 2)
        deskCM:addObj("Обновить", updateDesktop)
        if backImageExists then
            deskCM:addObj(-1)
            deskCM:addObj("Убрать обои", removeWallpaperFunc)
        end
    end
    reloadItems()
    initialized, changeBackground = true, false
end

function update(drawAll)
    init()
    ui.draw(mainBox, drawAll)
    ui.checkingObject = mainBox
    ui.args = {touch=touch}
end

function updateDesktop()
  update(true)
end

function execute(args, x, y, button)
    if button == 0 or button == nil then                -- LEFT MOUSE BUTTON
        itemsBox.objects[args.num * 2]:flash()
        local drawAll = false
        if args[1] == 1 then                                    -- DEFAULT FILE
            os.execute("edit " .. ui.addQuotes(deskPath .. args[2]))
            drawAll = true
        elseif args[1] == 2 then                                -- FOLDER
            deskPath = deskPath .. args[2] .. "/"
        elseif args[1] == 3 then                                -- LUA
            system.execute(deskPath .. args[2])
            drawAll = true
        elseif args[1] == 4 then                                -- APPLICATION
            if fs.exists(deskPath .. args[2] .. ".app/program.lua") then
                system.execute(deskPath .. args[2] .. ".app/program.lua")
                drawAll = true
            end
        elseif args[1] == 5 then
            os.execute("/SHELL/BIN/PIXELCREATOR.lua " .. ui.addQuotes(deskPath .. args[2]))
            drawAll = true
        end
        update(drawAll)
    elseif button == 1 then                             -- RIGHT MOUSE BUTTON
        itemsBox.objects[args.num * 2]:toggle(true)
        clickedItemText = args[2]
        if args[1] == 1 or args[1] == 3 or args[1] == 5 then    -- DEFAULT, LUA, IMAGE FILE
            defaultItemCM.globalX, defaultItemCM.globalY = x, y
            defaultItemCM:show()
        elseif args[1] == 2 then                                -- FOLDER
            folderCM.globalX, folderCM.globalY = x, y
            folderCM:show()
        elseif args[1] == 4 then                                -- APPLICATION
            appCM.globalX, appCM.globalY = x, y
            appCM:show()
        end
        if itemsBox.objects[args.num * 2] and itemsBox.objects[args.num * 2].args.active then itemsBox.objects[args.num * 2]:toggle() end
    end
end

if CFG.config == nil then CFG.config = {} end
if CFG.config.backColor == nil then CFG.config.backColor = 0x006D80 end
if CFG.config.iconsColor == nil then CFG.config.iconsColor = 0xFFFFFF end
CFG:save()

inet.download("https://raw.githubusercontent.com/motangish/OCUI/master/version.cfg", "/tmp/version.cfg")
newUIVersion = tonumber(file.open("/tmp/version.cfg"))
fs.makeDirectory(deskPath)
init()
ui.draw(mainBox, true)
ui.handleEvents(mainBox, {touch=touch})
