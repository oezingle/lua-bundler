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

---@class LuaBundle.Bundler.Options
---@field src string
---@field dest string
---@field uid string
---@field ignore string[]?
-- ---@field include { path: string, modname: string }[]
---@field ["public"] string?

---@class LuaBundle.Bundler : Log.BaseFunctions, LuaBundle.Bundler.Options
---@field paths { src: string, dest: string, lua_src: string, public: string? }
---@field stack LuaBundle.Bundler.StackItem[]
---@operator call: LuaBundle.Bundler
local Bundler         = class("Bundler.V2")

local check_functions = {
    "require",
    "package.searchpath"
}

---@param options LuaBundle.Bundler.Options
---@return LuaBundle.Bundler
function Bundler.create(options)
    return Bundler(options)
end

---@class LuaBundle.Bundler.StackItem.Dep
---@field type "dep"
---@field path string
---@field call_source string

---@class LuaBundle.Bundler.StackItem.FindModules
---@field type "find"
---@field path string

---@class LuaBundle.Bundler.StackItem.ModifySrc
---@field type "src"
---@field path string

---@alias LuaBundle.Bundler.StackItem LuaBundle.Bundler.StackItem.Dep | LuaBundle.Bundler.StackItem.FindModules | LuaBundle.Bundler.StackItem.ModifySrc

---@param options LuaBundle.Bundler.Options
function Bundler:init(options)
    self.paths = {}

    self.paths.src = options.src
    self.paths.dest = options.dest

    self.paths.lua_src = luaify(options.src)

    self.ignore = options.ignore or {}

    self.built = {}

    self.uid = options.uid

    self.paths.public = options.public

    -- self.include = options.include

    ---@type LuaBundle.Bundler.StackItem[]
    self.stack = {}

    log.debug(string.format(table.concat({
        "",
        "Bundler created",
        "[src: %q] [dest: %q] [uid: %q]",
        "[ignore: %s]",
    }, "\n"), self.paths.src, self.paths.dest, self.uid, table.concat(self.ignore, ", ")))
end

---@param item LuaBundle.Bundler.StackItem
function Bundler:stack_add(item)
    log.trace(string.format("[stack] add first { %s | %s }", item.type, item.path))

    table.insert(self.stack, 1, item)
end

---@param item LuaBundle.Bundler.StackItem
function Bundler:stack_add_last(item)
    log.trace(string.format("[stack] add last { %s | %s }", item.type, item.path))

    table.insert(self.stack, item)
end

---@param replacers { UUID: string }
function Bundler:get_shim(replacers)
    local path = package.searchpath("src.template.shim", package.path)

    if not path then
        error(string.format("Unable to determine path for template %q", "src.template.shim"))
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
        error(string.format("Unable to determine path for template %q", "src.template.export"))
    end

    local export = fs.read(path)

    for k, v in pairs(replacers) do
        export = export:gsub("<" .. k .. ">", v)
    end

    return lazy_minify(export)
end

---@param path string
function Bundler:is_ignored(path)
    for _, library in ipairs(self.ignore) do
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

---@param statement Lua-Parser.Node.Function
---@param filepath string
---@return boolean matched, boolean needs_shim
function Bundler:match_replaced_function(statement, filepath)
    if includes({"var", "index" }, statement.func.type) and includes(check_functions, tostring(statement.func)) then

        local first_arg = statement.args[1]

        -- non-string results are dynamic requires
        if first_arg.type == "string" then
            local require_path = first_arg.value

            local lua_src = self.paths.lua_src

            -- is within src
            if require_path:sub(1, #lua_src) == lua_src then
                first_arg.value = self.uid .. require_path:sub(1 + #lua_src)
            elseif not self:is_ignored(require_path) then
                -- this dependency is not a library that this install of lua should expect

                -- replace require or search with <uid>._dep.<path>
                first_arg.value = table.concat({ self.uid, DEP_FOLDER_NAME, require_path }, ".")

                self:stack_add({
                    type = "dep",
                    path = require_path,
                    call_source = filepath
                })
            end

            return true, true
        else
            -- TODO incorrectly reads line number?
            -- local line = statement.span.from.line

            log.warn(string.format(
                "Found dynamic require in %s. This cannot be bundled and may result in broken behaviour.",
                filepath
            ))
        end

        return true, false
    end

    return false, false
end

---@param statement any
---@param filepath string
---@return boolean needs_shim
function Bundler:recurse_ast(statement, filepath)
    if not statement then
        return false
    end

    -- log.trace("statement type", statement.type)

    if statement.type == "call" then
        local matched, needs_shim = self:match_replaced_function(statement, filepath)

        if not matched then
            self:recurse_ast(statement.func, filepath)

            self:recurse_ast_list(statement.args, filepath)
        end

        return needs_shim
    elseif includes({ "assign", "local", "return" }, statement.type) then
        return self:recurse_ast_list(statement.exprs, filepath)
    elseif statement.type == "index" then
        return self:recurse_ast(statement.expr, filepath)
    elseif statement.type == "if" then
        local shim_if = self:recurse_ast_list(statement, filepath)

        local shim_cond = self:recurse_ast(statement.cond, filepath)

        local shim_elseifs = self:recurse_ast_list(statement.elseifs, filepath)
        
        local shim_else = self:recurse_ast(statement.elsestmt, filepath)

        return shim_if or shim_cond or shim_elseifs or shim_else
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
        log.info(string.format("[src] Installing shim in %q", absolute_out))

        local relative_path = basename(relative_path):gsub("[/\\]", ".")
        if #relative_path > 0 and not relative_path:match("%.$") then
            relative_path = relative_path .. "."
        end

        contents = self:get_module_header({
            OUTDIR_END = basename(absolute_out):match("[/\\]([^/\\]+)$") or "",
            RELATIVE_PATH = relative_path
        }) .. "\n" .. contents
    end

    log.debug(string.format("[src] Writing to %s", absolute_out))
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

        log.debug(string.format("[find] Found %q -> %q", absolute_file_in, absolute_file_out))

        local relative_file = join(relative_path, file)

        if fs.is_dir(absolute_file_in) then
            -- self:find_modules(relative_file)
            self:stack_add_last({
                type = "find",
                path = relative_file
            })
        elseif is_lua_file(absolute_file_in) then
            -- self:modify_source_file(relative_file)
            self:stack_add({
                type = "src",
                path = relative_file
            })
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

---@param luapath string
---@param reqpath string
function Bundler:handle_dependency(luapath, reqpath)
    local dep_path = join(self.paths.dest, DEP_FOLDER_NAME)

    fs.mkdir_p(dep_path)

    local path = package.searchpath(luapath, package.path)

    if not path then
        error(string.format("Unable to determine path for dependency %q (required by %s)", luapath, reqpath))
    end

    local path_out = join(dep_path, path)

    log.debug(string.format("[dep] Found %q -> %q", path, path_out))

    local dir_out = basename(path_out)
    fs.mkdir_p(dir_out)

    local contents = fs.read(path)

    local ast = parser.parse(contents)

    log.trace(string.format("Checking AST of %q", path))

    self:recurse_ast_list(ast, path)

    local contents = tostring(ast)

    fs.write(path_out, contents)
end

function Bundler:publish_public()
    local dir = self.paths.public

    if not dir then
        return
    end

    log.info(string.format("Copying public files from %q", dir))

    for _, file in ipairs(fs.ls(dir)) do
        local full_in = join(dir, file)
        local full_out = join(self.paths.dest, file)

        fs.cp(full_in, full_out)
    end
end

function Bundler:run()
    self:find_modules("")

    while #self.stack ~= 0 do
        local first = table.remove(self.stack, 1)

        log.trace(string.format("built %s: %s", first.path, self.built[first.path] and "yes" or "no"))

        if not self.built[first.path] then
            if first.type == "dep" then
                self:handle_dependency(first.path, first.call_source)
            elseif first.type == "find" then
                self:find_modules(first.path)
            elseif first.type == "src" then
                self:modify_source_file(first.path)
            else
                error(string.format("Unhandled stack item type %q", first.type))
            end

            self.built[first.path] = true
        end
    end

    self:add_shim()

    self:publish_public()
end

return Bundler
