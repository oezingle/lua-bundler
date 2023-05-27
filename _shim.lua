if not ... then
    error("this file must be require()'d")
end

local folder_of_this_file = (...):match("(.-)%.[^%.]+$")

local function add_this_library()
    local uuid = "f4564065%-24e2%-49de%-921b%-6867a247b8f4"

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
