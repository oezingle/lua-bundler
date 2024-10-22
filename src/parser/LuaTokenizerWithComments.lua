local LuaTokenizer = require("lib.lua-parser.lua.tokenizer")

local LuaTokenizerWithComments = LuaTokenizer:subclass()

function LuaTokenizerWithComments:parseComment()
    local r = self.r
    if r:canbe(self.singleLineComment) then
        local start = r.index - #r.lasttoken
        -- read block comment if it exists
        if not r:readblock() then
            -- read line otherwise
            if not r:seekpast '\n' then
                r:seekpast '$'
            end
        end
        local commentstr = r.data:sub(start, r.index - 1)
        coroutine.yield(commentstr, 'comment')
        return true
    end
end

return LuaTokenizerWithComments
