local fs = require("filesystem")
local sr = require("serialization")

local config = {}
config.__index = config

function config.open(path)
    local f = io.open(path, "r")
    local data
    if f then
        data = sr.unserialize(f:read("*a"))
        f:close()
    end
    return data
end

function config.new(path)
    local self = setmetatable({}, config)
    self.config = config.open(path)
    self.path = path
    return self
end

function config:save()
    if fs.exists(self.path) then fs.remove(self.path) end
    fs.makeDirectory(fs.path(self.path))
    local f = fs.open(self.path, "w")
    f:write(sr.serialize(self.config))
    f:close()
end

return config
