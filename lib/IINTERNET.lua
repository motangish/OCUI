local fs = require("filesystem")
local inet = require("internet")

local internet = {}

function internet.download(url, path)
  local result, response = pcall(inet.request, url)
  if not result then return false end
  if fs.exists(path) then fs.remove(path) end
  fs.makeDirectory(fs.path(path))
  local file = io.open(path, "w")
  for data in response do file:write(data) end
  file:close()
  return true
end

return internet
