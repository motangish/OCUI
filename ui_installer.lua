local sr   = require("serialization")
local inet = require("internet")
local fs   = require("filesystem")
local comp = require("computer")
local ui   = require("UI")

local mainWindow, progressBar

local filesCount
local filesDownloaded = 0
local data

local function download(path, localPath)
    local result, response = pcall(inet.request, "https://raw.githubusercontent.com/motangish/OCUI/master" .. path)
    if result then
        local newPath = localPath or path
        if fs.exists(newPath) then fs.remove(newPath) end
        fs.makeDirectory(fs.path(newPath))
        local file = io.open(newPath, "w")
        for data in response do file:write(data) end
        file:close()
    end
end

local function printPercent()
    progressBar:setProgress(math.floor((100 / filesCount) * filesDownloaded))
    gpu.setBackground(0x1C1C1C)
    gpu.setForeground(0xFFFFFF)
    gpu.set(3, 2, math.floor((100 / filesCount) * filesDownloaded) .. "%      ")
end

local function init()
    mainWindow = ui.window(nil, nil, 60, 4, 0xC3C3C3, 0x006DBF, 0xFFFFFF, "Обновление системы", true)
    progressBar = ui.standartProgressBar(3, 3, 56, 1, 0xA5A5A5, 0x1C1C1C, 10, 5)
    mainWindow:addObj(progressBar)
end

download("/install_files.cfg", "/tmp/install_files.cfg")
local file = io.open("/tmp/install_files.cfg", "r")
data = sr.unserialize(file:read("*a"))
file:close()

filesCount = #data.libs + #data.icons + #data.bin + #data.other + (#data.apps * 2)

init()
ui.draw(mainWindow)
ui.checkingObject, ui.args = nil, nil

for i = 1, #data.libs do
    download("/lib/" .. data.libs[i] .. ".lua")
    filesDownloaded = filesDownloaded + 1
    printPercent()
end

for i = 1, #data.icons do
    download("/SHELL/ICONS/" .. data.icons[i] .. ".bpix")
    filesDownloaded = filesDownloaded + 1
    printPercent()
end

for i = 1, #data.bin do
    download("/SHELL/BIN/" .. data.bin[i] .. ".lua")
    filesDownloaded = filesDownloaded + 1
    printPercent()
end

for i = 1, #data.other do
    download(data.other[i])
    filesDownloaded = filesDownloaded + 1
    printPercent()
end

for i = 1, #data.apps do
    download("/SHELL/APPLICATIONS/" .. data.apps[i] .. "/info.cfg", "/tmp/info.cfg")
    local file = io.open("/tmp/info.cfg", "r")
    local name = sr.unserialize(file:read("*a")).name
    file:close()
    download("/SHELL/APPLICATIONS/" .. data.apps[i] .. "/program.lua", "/SHELL/DESKTOP/" .. name .. ".app/program.lua")
    filesDownloaded = filesDownloaded + 1
    printPercent()
    download("/SHELL/APPLICATIONS/" .. data.apps[i] .. "/icon.bpix", "/SHELL/DESKTOP/" .. name .. ".app/icon.bpix")
    filesDownloaded = filesDownloaded + 1
    printPercent()
end

os.sleep(1)
comp.shutdown(1)
