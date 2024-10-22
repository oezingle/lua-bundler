local function parser_shim()
    package.loaded["ext.op"]                 = require("lib.lua-ext.op")
    package.loaded["ext.table"]              = require("lib.lua-ext.table")
    package.loaded["ext.class"]              = require("lib.lua-ext.class")
    package.loaded["ext.string"]             = require("lib.lua-ext.string")
    package.loaded["ext.tolua"]              = require("lib.lua-ext.tolua")
    package.loaded["ext.assert"]             = require("lib.lua-ext.assert")

    package.loaded["parser.base.ast"]        = require("lib.lua-parser.base.ast")
    package.loaded["parser.lua.ast"]         = require("lib.lua-parser.lua.ast")

    package.loaded["parser.base.datareader"] = require("lib.lua-parser.base.datareader")

    package.loaded["parser.base.tokenizer"]  = require("lib.lua-parser.base.tokenizer")
    package.loaded["parser.lua.tokenizer"]   = require("lib.lua-parser.lua.tokenizer")

    package.loaded["parser.base.parser"]     = require("lib.lua-parser.base.parser")
    package.loaded["parser.lua.parser"]      = require("lib.lua-parser.lua.parser")

    -- ---@alias Lua-Parser.Exprs { [number]: Lua-Parser.Node, span: Lua-Parser.Span }
    -- ---@alias Lua-Parser.Variable { span: Lua-Parser.Span, name: string, parent: Lua-Parser.Node }
    -- ---@alias Lua-Parser.Node { exprs: Lua-Parser.Exprs, parent: Lua-Parser.Node, span: Lua-Parser.Span, vars?: Lua-Parser.Variable[], name?: string }

    ---@alias Lua-Parser.Location { col: integer, line: integer }
    ---@alias Lua-Parser.Span { from: Lua-Parser.Location, to: Lua-Parser.Location }

    ---@class Lua-Parser.Parser 
    ---@field getloc fun(self: self): Lua-Parser.Location
    ---@field node fun(self: self, type: string, ...: any): Lua-Parser.CNode
    ---@field version string
    ---@field lasttoken string
    ---@field canbe fun(self: self, token: string?, tokentype: string): (string, string) | nil Optionally catch a token by its type
    ---@field mustbe fun(self: self, token: string?, tokentype: string): (string, string) Like canbe, but expect this token
    
    ---@class Lua-Parser.LuaParser : Lua-Parser.Parser
    ---@field super Lua-Parser.Parser
    ---@field parse_stat fun (self: self): Lua-Parser.CNode? Parse the next statement made available
    ---@field init fun(self: self, data: string, version: string?, source: string?, useluajit: boolean?): self Initialize a member of this class
    ---@field useluajit boolean automatically set if not chosen

    ---@class Lua-Parser.CNode
    ---@field span Lua-Parser.Span
    ---@field copy fun(self: self): self
    ---@field flatten fun(self:self, func: function, varmap: any) TODO Not sure how this works whatsoever
    ---@field toLua fun(self: self): string
    ---@field serialize fun(self: self, apply: function) TODO not sure how this works
    ---@field setspan fun(self: self, span: Lua-Parser.Span): self
    ---@operator call:Lua-Parser.CNode

    ---@class Lua-Parser.Node.Function : Lua-Parser.CNode
    ---@field type "function"
    ---@field func Lua-Parser.Node
    ---@field args Lua-Parser.Node[]

    ---@class Lua-Parser.Node.String
    ---@field type "string"
    ---@field value string

    ---@class Lua-Parser.Node.If
    ---@field type "if"
    ---@field cond Lua-Parser.Node
    ---@field elseifs Lua-Parser.Node[]
    ---@field elsestmt Lua-Parser.Node

    ---@alias Lua-Parser.Node Lua-Parser.CNode | Lua-Parser.Node.Function | Lua-Parser.Node.String | Lua-Parser.Node.If

    ---@type { parse: fun(lua: string): Lua-Parser.Node }
    return require("lib.lua-parser.parser")
end

return parser_shim()
