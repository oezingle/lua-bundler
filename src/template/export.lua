do
    local folder_of_this_file

    local module_arg = { ... }

    if module_arg[1] ~= (arg or {})[1] then
        folder_of_this_file = module_arg[1] .. "."

        -- A match here means resolved as init
        local is_implicit_init = module_arg[2]:match(module_arg[1] .. "[/\\]init%.lua")

        if not is_implicit_init then
            folder_of_this_file = folder_of_this_file:match("(.+%.)[^.]+") or ""
        end
    else
        -- file is 'main'
        ---@type string
        folder_of_this_file = arg[0]:gsub("[^%./\\]+%..+$", "")

        -- Hack to allow running this file from outside its own directory
        do
            local sep = package.path:sub(1, 1)

            ---@type string
            local pwd = sep == "/" and os.getenv("PWD") or io.popen("cd", "r"):read("a")
            -- for every .. in folder_of_this_file, remove one layer from the end of pwd. ends up finding them common ground!
            for _ in folder_of_this_file:gmatch("%.%.") do
                pwd = pwd:gsub("[/\\][^/\\]+[/\\]?$", "")
            end
            -- add trailing slash
            pwd = pwd .. sep

            -- add to package.path
            package.path = package.path .. string.format(";%s?.lua;%s?%sinit.lua", pwd, pwd, sep)
        end

        folder_of_this_file = folder_of_this_file
            -- replace slashes with dots
            :gsub("[/\\]", ".")
            -- remove any starting dots
            :gsub("^%.+", "")
    end

    local library_root = folder_of_this_file:sub(1, -1 - #"<RELATIVE_PATH>")

    require(library_root .. "_shim")
end
