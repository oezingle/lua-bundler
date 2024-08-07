
local basename = require("src.polyfill.path.basename")
local join = require("src.polyfill.path.join")
local sep = require("src.polyfill.path.sep")
local split = require("src.polyfill.string.split")
local reduce = require("src.polyfill.list.reduce")
local mkdir = require("src.fs.mkdir").mkdir
local exists = require("src.fs.exists")
local is_dir = require("src.fs.is_dir")

---@param path string
local function mkdir_p (path)
    local dir = basename(path)
    
    local slices = split(dir, sep)
    
    reduce(slices, function (previous, slice)
        local path = join(previous, slice)

        if not exists(path) then
            mkdir(path)
        elseif not is_dir (path) then
            error(string.format("Path %q is a file - directory expected!", path))
        end

        return path
    end, "")
end

return mkdir_p