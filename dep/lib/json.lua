--- required by build/bundler/src/init.lua
local json = require("d6ea20b3-f49b-4619-a9fc-161a90700ab1.dep.lib.json.json")
if false then
    json = {
        --- Turn a lua table into a JSON serialized string
        ---@param table table
        ---@return string json
        encode = function (table) return json.encode(table) end,
        --- Turn a JSON serialized string into a lua table
        ---@param str string
        ---@return table table
        decode = function (str) return json.decode(str) end
    }
end
return json