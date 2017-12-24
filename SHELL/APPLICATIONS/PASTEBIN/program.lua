local ui = require("UI")
local inet = require("IINTERNET")

local mainWindow, idTB, pathTB, downButton, closeButton

local function close()
    mainWindow = nil
    os.exit()
end

local function download()
    local id, path = idTB.text, pathTB.text
    if id ~= "" and path ~= "" then
        inet.download("https://pastebin.com/raw/" .. id, pathTB.text)
    end
end

window = ui.window(nil, nil, 40, 10, 0xDCDCDC, 0xCDCDCD, 0, "Pastebin", true)
idTB = ui.beautifulTextbox(2, 2, 38, 0xC3C3C3, 0x1C1C1C, "Paste ID", 8)
pathTB = ui.beautifulTextbox(2, 5, 38, 0xC3C3C3, 0x1C1C1C, "Path to file", nil)
closeButton = ui.beautifulButton(2, 8, nil, 3, 0xDCDCDC, 0x660000, "Закрыть", close)
downButton = ui.beautifulButton(29, 8, nil, 3, 0xDCDCDC, 0x006600, "Скачать", download)

window:addObj(idTB)
window:addObj(pathTB)
window:addObj(closeButton)
window:addObj(downButton)

ui.draw(window)
ui.handleEvents(window)
