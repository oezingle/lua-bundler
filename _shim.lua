if not ... then
    error("this file must be require()'d")
end

local folder_of_this_file = (...):match("(.-)%.[^%.]+$")

local function add_this_library()
    local uuid = "85374dcb%-f074%-4f19%-a493%-12bd7d7c1966"

    ---@param libraryname string
    table.insert(package.searchers, function(libraryname)
        if libraryname:match("^" .. uuid) then
            local resolved_path = libraryname:gsub(uuid, folder_of_this_file)

            -- this works because this searcher will always remove the uuid,
            -- therefore removing what triggered the searcher itself
            return function() return require(resolved_path) end
        end
    end)
end

add_this_library()
