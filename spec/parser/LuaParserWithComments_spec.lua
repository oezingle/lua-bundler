local LuaParserWithComments = require("src.parser.LuaParserWithComments")

local function load_ast (ast)
    local get_chunk, err = load(tostring(ast), "Reconstructed AST")

    if err then
        error(err)
    end

    return get_chunk
end

describe("LuaParserWithComments", function()
    it("Finds comment lines", function()
        local ast = LuaParserWithComments.parse([[    
            -- I'm a comment!    
        ]])

        assert.has.match("I'm a comment", tostring(ast))
    end)

    it("Finds block comments", function ()
        local ast = LuaParserWithComments.parse("--[[ I'm a comment! ]]")

        assert.has.match("I'm a comment", tostring(ast))
    end)

    it("Returns code after comments", function ()
        local ast = LuaParserWithComments.parse([[
            -- I'm a comment

            local a = true

            return a
        ]])

        assert.has.match("I'm a comment", tostring(ast))

        local exec = load_ast(ast)

        assert.True(exec())
    end)

    it("Returns code after block comments", function ()
        local ast = LuaParserWithComments.parse("--[[ I'm a comment! ]]" .. [[
            local a = true

            return a
        ]])

        assert.has.match("I'm a comment", tostring(ast))

        local exec = load_ast(ast)

        assert.True(exec())
    end)

    it("Allows comments in the middle of code", function ()
        local ast = LuaParserWithComments.parse([[
            local a = true

            -- I'm a comment

            return a
        ]])
        
        assert.has.match("I'm a comment", tostring(ast))

        local exec = load_ast(ast)

        assert.True(exec())
    end)

    it("allows comments in blocks", function ()
        local ast = LuaParserWithComments.parse([[
            do
                local a = true

                -- I'm a comment

                return a
            end
        ]])
        
        assert.has.match("I'm a comment", tostring(ast))

        local exec = load_ast(ast)

        assert.True(exec())
    end)
    
    it("allows comments in blocks", function ()
        local ast = LuaParserWithComments.parse([[
            do
                local a = true

                return a

                -- I'm a comment
            end
        ]])
        
        assert.has.match("I'm a comment", tostring(ast))

        local exec = load_ast(ast)

        assert.True(exec())
    end)

    it("allows keeping only annotations", function ()
        local ast = LuaParserWithComments.parse([[
            ---@type true
            local a = true

            -- I'm a comment

            return a
        ]], nil, nil, nil, true)

        assert.has_no.match("I'm a comment", tostring(ast))

        local exec = load_ast(ast)

        assert.True(exec())
    end)
end)
