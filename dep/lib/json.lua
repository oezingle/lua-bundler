--- required by build/bundler/src/init.lua
local json = require("f28ad920-cbc7-4d29-b568-ae59cecf0c40.dep.lib.json.json")
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