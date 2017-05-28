local fs = require("filesystem")

local file = {}

function file.save(path, data)
  if fs.exists(path) then fs.remove(path) end
  fs.makeDirectory(fs.path(path))
  local f = fs.open(path, "w")
  f:write(data)
  f:close()
end

function file.open(path)
  local f = io.open(path, "r")
  local data = f:read("*a")
  f:close()
  return data
end

return file
