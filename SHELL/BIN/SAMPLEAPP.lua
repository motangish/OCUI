local ui = require("UI")

local mainWindow, closeButton

local function close()
  mainWindow = nil
  os.exit()
end

window = ui.window(nil, nil, 50, 15, 0xDCDCDC, 0xCDCDCD, 0, "Sample Application", true)
closeButton = ui.beautifulButton(2, 13, nil, 3, 0xDCDCDC, 0x660000, "Закрыть", close)

window:addObj(closeButton)

ui.draw(window)
ui.handleEvents(window)