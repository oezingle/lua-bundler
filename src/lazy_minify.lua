---@nospec honestly this doesn't have to do anything but generate valid lua.

local parser = require("lib.lua-parser")

local function lazy_minify(lua)
    return tostring(parser.parse(lua))
end 

return lazy_minify