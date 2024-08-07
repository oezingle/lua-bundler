local random = math.random

--- Pure-lua function to generate a UUID
---@source https://gist.github.com/jrus/3197011
---@return string uuid
local function uuid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'

    local uuid = string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)

    return uuid
end

return uuid