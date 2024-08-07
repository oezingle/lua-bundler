local class           = require("lib.30log")
local parser          = require("lib.lua-parser")
local log             = require("lib.log")

local fs              = require("src.fs.init")

local join            = require("src.polyfill.path.join")
local basename        = require("src.polyfill.path.basename")
local includes        = require("src.polyfill.list.includes")

local is_lua_file     = require("src.is_lua_file")
local lazy_minify     = require("src.lazy_minify")

local luaify          = require("src.resolve.luaify")

local DEP_FOLDER_NAME = "_dep"

---@class LuaBundle.Bundler : Log.BaseFunctions
---@operator call: LuaBundle.Bundler
local Bundler         = class("Bundler.V2")

local check_functions = {
    "require",
    "package.searchpath"
}

---@class LuaBundle.Bundler.Options
---@field src string
---@field dest string
---@field uid string
---@field libraries string[]?

---@param options LuaBundle.Bundler.Options
function Bundler:init(options)
    self.paths = {}

    self.paths.src = options.src
    self.paths.dest = options.dest

    -- TODO distinct options?
    self.paths.lua_src = luaify(options.src)

    self.libraries = options.libraries or {}

    self.built = {}

    self.uid = options.uid
end

---@param replacers { UUID: string }
function Bundler:get_shim(replacers)
    local path = package.searchpath("src.template.shim", package.path)

    if not path then
        error(string.format("Unable to resolve template %q to real path", "src.template.shim"))
    end

    local shim = fs.read(path)

    for k, v in pairs(replacers) do
        shim = shim:gsub("<" .. k .. ">", v)
    end

    return lazy_minify(shim)
end

---@param replacers { OUTDIR_END: string, RELATIVE_PATH: string }
function Bundler:get_module_header(replacers)
    -- TODO would be nice for these 'dynamic' imports to be something i can flatten down
    local path = package.searchpath("src.template.export", package.path)

    if not path then
        error(string.format("Unable to resolve template %q to real path", "src.template.export"))
    end

    local export = fs.read(path)

    for k, v in pairs(replacers) do
        export = export:gsub("<" .. k .. ">", v)
    end

    return lazy_minify(export)
end

---@param path string
function Bundler:is_library(path)
    for _, library in ipairs(self.libraries) do
        if path:sub(1, #library) == library then
            return true
        end
    end

    return false
end

---@param ast Lua-Parser.Node
---@param filepath string
function Bundler:recurse_ast_list(ast, filepath)
    local needs_shim = false

    for _, statement in ipairs(ast) do
        local inner_needs_shim = self:recurse_ast(statement, filepath)
        
        needs_shim = needs_shim or inner_needs_shim
    end

    return needs_shim
end

---@param statement any
---@param filepath string
---@return boolean needs_shim
function Bundler:recurse_ast(statement, filepath)
    if statement.type == "call" then
        for _, func_name in ipairs(check_functions) do
            if tostring(statement.func) == func_name then
                local first_arg = statement.args[1]

                -- non-string results are dynamic requires
                if first_arg.type == "string" then
                    local require_path = first_arg.value

                    local lua_src = self.paths.lua_src

                    if require_path:sub(1, #lua_src) == lua_src then
                        first_arg.value = self.uid .. require_path:sub(1 + #lua_src)
                    else
                        if not self:is_library(require_path) then
                            first_arg.value = table.concat({ self.uid, DEP_FOLDER_NAME, require_path }, ".")
                            -- first_arg.value = self.uid .. "._dep." .. require_path

                            if not self.built[require_path] then
                                self:handle_dependency(require_path)

                                self.built[require_path] = true 
                            end
                        end
                    end

                    return true
                else
                    -- TODO incorrectly reads line number?
                    -- local line = statement.span.from.line

                    log.warn(string.format(
                        "Found dynamic require in %s. This cannot be bundled and may result in broken behaviour.",
                        filepath
                    ))
                end
            end
        end

        return false
    elseif includes({ "assign", "local", "return" }, statement.type) then
        return self:recurse_ast_list(statement.exprs, filepath)
    elseif includes({ "index" }, statement.type) then
        return self:recurse_ast(statement.expr, filepath)
    else
        return self:recurse_ast_list(statement, filepath)
    end
end

---@param relative_path string
function Bundler:modify_source_file(relative_path)
    local absolute_in = join(self.paths.src, relative_path)
    local absolute_out = join(self.paths.dest, relative_path)

    local contents = fs.read(absolute_in)

    local ast = parser.parse(contents)

    local needs_shim = self:recurse_ast_list(ast, absolute_in)

    local contents = tostring(ast)

    if needs_shim then
        log.info(string.format("Installing shim in %q", absolute_out))

        local relative_path = basename(relative_path):gsub("[/\\]", ".")
        if #relative_path > 0 and not relative_path:match("%.$") then
            relative_path = relative_path .. "."
        end

        contents = self:get_module_header({
            OUTDIR_END = basename(absolute_out):match("[/\\]([^/\\]+)$") or "",
            RELATIVE_PATH = relative_path
        }) .. "\n" .. contents
    end

    fs.write(absolute_out, contents)
end

---@param path string
function Bundler:find_modules(path)
    local relative_path = path

    local absolute_in = join(self.paths.src, relative_path)
    local absolute_out = join(self.paths.dest, relative_path)

    fs.mkdir_p(absolute_out)

    for _, file in ipairs(fs.ls(absolute_in)) do
        local absolute_file_in = join(absolute_in, file)
        local absolute_file_out = join(absolute_out, file)

        log.debug(string.format("[src] Found %q -> %q", absolute_file_in, absolute_file_out))

        local relative_file = join(relative_path, file)

        if fs.is_dir(absolute_file_in) then
            self:find_modules(relative_file)
        elseif is_lua_file(absolute_file_in) then
            self:modify_source_file(relative_file)
        else
            fs.cp(absolute_file_in, absolute_file_out)
        end
    end
end

function Bundler:add_shim()
    local path = join(self.paths.dest, "_shim.lua")

    local contents = self:get_shim({
        UUID = self.uid
    })

    fs.write(path, contents)
end

function Bundler:handle_dependency(luapath)
    local dep_path = join(self.paths.dest, DEP_FOLDER_NAME)

    fs.mkdir_p(dep_path)

    local path = package.searchpath(luapath, package.path)

    if not path then
        error(string.format("Unable to determine path for dependency %q", luapath))
    end

    local path_out = join(dep_path, path)

    log.debug(string.format("[dep] Found %q -> %q", path, path_out))

    local dir_out = basename(path_out)
    fs.mkdir_p(dir_out)

    local contents = fs.read(path)

    local ast = parser.parse(contents)

    self:recurse_ast_list(ast, path)

    local contents = tostring(ast)

    fs.write(path_out, contents)
end

function Bundler:run()
    self:find_modules("")

    self:add_shim()
end

return Bundler
