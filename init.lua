
local folder_of_this_file

-- https://stackoverflow.com/questions/4521085/main-function-in-lua
if pcall(debug.getlocal, 4, 1) then
    folder_of_this_file = (...):match("(.-)[^%.]+$")
else
    folder_of_this_file = arg[0]:gsub("[^%./\\]+%..+$", ""):gsub("[/\\]", ".")
end

require(folder_of_this_file .. "_shim")

-- TODO @path
return require("ca521080-bb22-46ca-b87a-b77860b17c67.src.init")