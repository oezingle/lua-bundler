
require("lib.lua-parser")

local lua_ast = require("lib.lua-parser.lua.ast")

local _comment = lua_ast.nodeclass("comment")

function _comment:init (...)
    local contents = ({...})[1]
    
    self.contents = contents:gsub("\n$", "")
end

function _comment:serialize (apply)
    return self.contents
end

return _comment