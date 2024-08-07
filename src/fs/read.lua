
---@param path string
---@return string
---@nodiscard
local function read (path)
    local file = io.open(path, "r")

    if not file then
        error(string.format("Unable to open file %q for reading", path))
    end

    return file:read("a")
end

return read