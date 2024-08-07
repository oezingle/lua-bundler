---@param path string
---@return string
local function luaify(path)
    local replaced = path
        -- remove .lua extension
        :gsub("%.lua$", "")
        -- remove leading slash
        :gsub("^[/\\]", "")
        -- replace slash with .
        :gsub("[/\\]", ".")

    return replaced
end

return luaify
