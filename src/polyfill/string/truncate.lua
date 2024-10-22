--- Truncate a string to a given length, or 80 chars by default
---@param str string
---@param length integer?
local function string_truncate(str, length)
    length = length or 80

    str = str:match("^[.-]\n") or str

    if #str > length + 3 then
        return str:sub(1, length - 3) .. "..."
    end

    return str
end

return string_truncate
