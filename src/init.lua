local vararg  = table.pack(...)

local cli     = require("src.cli")
local Bundler = require("src.Bundler")

local function main()
    if vararg[1] == (arg or {})[1] then
        cli()
    else
        return Bundler
    end
end

return main()
