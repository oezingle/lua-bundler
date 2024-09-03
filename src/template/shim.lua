if not ... then
    error("this file must be loaded via require()")
end

local folder_of_this_file = (...):match("(.-%.)[^%.]+$") or ""

local uuid = "<UUID>"

---@param libraryname string
local function loader(libraryname)
    if libraryname:sub(1, #uuid) == uuid then
        local resolved_path = folder_of_this_file .. libraryname:sub(2 + #uuid)

        -- this works because this searcher will always remove the uuid,
        -- therefore removing what triggered the searcher itself
        return function()
            return require(resolved_path)
        end
    end
end

-- TODO I don't love modifying searchpath - this is not behaviour that
-- vanilla Lua expects, nor should I expect that it's modifiable in all
-- environments
local vanilla_searchpath = package.searchpath
---@param name string
---@param path string
---@param sep string?
---@param rep string?
local function modified_searchpath(name, path, sep, rep)
    if name:sub(1, #uuid) == uuid then
        local resolved_path = folder_of_this_file .. name:sub(2 + #uuid)

        return vanilla_searchpath(resolved_path, path, sep, rep)
    end

    return vanilla_searchpath(name, path, sep, rep)
end

local function add_custom_loader()
    ---@diagnostic disable-next-line:deprecated
    table.insert(package.searchers or package.loaders, loader)

    package.searchpath = modified_searchpath
end

add_custom_loader()
