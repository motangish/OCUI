local cmp   = require("component")
local sides = require("sides")

local reds = {}

function reds.getRedstone(address)
    return cmp.proxy(cmp.get(address))
end

return reds