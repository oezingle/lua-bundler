do
    local folder_of_this_file

    if table.pack(...)[1] ~= (arg or {})[1] then
        -- file has been imported
        folder_of_this_file = (...):match("(.-)[^%.]+$")

        -- importing files like src/some_folder/init.lua with
        -- require("src.some_folder") will resolve to src. this is no good!
        if not folder_of_this_file:match("<OUTDIR_END>%.$") then
            folder_of_this_file = folder_of_this_file .. "<OUTDIR_END>."
        end
    else
        -- file is 'main'
        folder_of_this_file = arg[0]:gsub("[^%./\\]+%..+$", ""):gsub("[/\\]", ".")
    end

    -- TODO test this!
    local library_root = folder_of_this_file:sub(1, - 1 - #"<RELATIVE_PATH>")
    
    require(library_root .. "_shim")
end

