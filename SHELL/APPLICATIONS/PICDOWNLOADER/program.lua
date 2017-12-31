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
    progressBar:setProgress(filesDownloaded)
end

local function init()
    mainWindow = ui.window(nil, nil, 60, 4, 0xC3C3C3, 0x006DBF, 0xFFFFFF, "Загрузка изображений", true)
    progressBar = ui.standartProgressBar(3, 3, 56, 1, 0xA5A5A5, 0x1C1C1C, filesCount, 0)
    mainWindow:addObj(progressBar)
end

download("/install_files.cfg", "/tmp/install_files.cfg")
local file = io.open("/tmp/install_files.cfg", "r")
data = sr.unserialize(file:read("*a"))
file:close()

filesCount = #data.pictures

init()
ui.draw(mainWindow)
ui.checkingObject, ui.args = nil, nil

for i = 1, #data.pictures do
    download("/SHELL/PICTURES/" .. data.pictures[i] .. ".bpix")
    filesDownloaded = filesDownloaded + 1
    printPercent()
end
