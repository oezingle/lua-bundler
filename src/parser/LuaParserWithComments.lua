-- install the _comment node
require("src.parser.comment")

local table = require("lib.lua-ext.table")

local truncate = require("src.polyfill.string.truncate")

local log = require("lib.log")

local LuaParser = require("lib.lua-parser.lua.parser")
local LuaTokenizerWithComments = require("src.parser.LuaTokenizerWithComments")

---@class LuaBundler.LuaParserWithComments : Lua-Parser.LuaParser
---@field super Lua-Parser.LuaParser
---@field stmt_comments table?
local LuaParserWithComments = LuaParser:subclass()

function LuaParserWithComments.parse(...)
    return LuaParserWithComments(...).tree
end

function LuaParserWithComments:init(data, version, source, useluajit, annotations_only)
    self.preserve_annotations_only = annotations_only or false

    self.super.init(self, data, version, source, useluajit)
end

function LuaParserWithComments:buildTokenizer(data)
    return LuaTokenizerWithComments(data, self.version, self.useluajit)
end

---@param from Lua-Parser.Location
function LuaParserWithComments:parse_comment(from)
    local contents = self.lasttoken

    -- TODO maybe move to tokenizer? tokenizer could simply not yield non-annotation comments
    if self.preserve_annotations_only and not contents:match("^%-%-%-%s*@") then
        return self:node("_comment", "")
    end

    return self:node("_comment", contents)
        :setspan({ from = from, to = self:getloc() })
end

--- nearly vanilla, but stmts is published to self.stmt_comments
function LuaParserWithComments:parse_chunk()
    local last_stmt_comments = self.stmt_comments

    local from = self:getloc()

	local stmts = table()
    self.stmt_comments = stmts
	
    repeat
		local stmt = self:parse_stat()
		if not stmt then break end
		stmts:insert(stmt)
		if self.version == '5.1' then
			self:canbe(';', 'symbol')
		end
	until false
	local laststat = self:parse_retstat()
	if laststat then
		stmts:insert(laststat)
		if self.version == '5.1' then
			self:canbe(';', 'symbol')
		end
	end
    
    self.stmt_comments = last_stmt_comments
	
    return self:node('_block', table.unpack(stmts))
		:setspan{from = from, to = self:getloc()}
end

function LuaParserWithComments:parse_stat()
    -- Stolen from vanilla parser - skip any ;
    if self.version >= "5.2" then
        repeat until not self.super.canbe(self, ";", "symbol")
    end

    local from = self:getloc()

    if self.super.canbe(self, nil, "comment") then
        log.debug(string.format("Keeping comment %q", truncate(self.lasttoken)))

        return self:parse_comment(from)
    end

    -- log.trace(self.t.token, self.t.tokentype)

    return self.super.parse_stat(self)
end

function LuaParserWithComments:canbe(token, tokentype)
    while self.super.canbe(self, nil, "comment") do
        if self.stmt_comments then
            local node = self:parse_comment(self:getloc())

            table.insert(self.stmt_comments, node)
        else
            log.error(string.format("Discarding comment %q", truncate(self.lasttoken)))
        end
    end

    return self.super.canbe(self, token, tokentype)
end

return LuaParserWithComments
