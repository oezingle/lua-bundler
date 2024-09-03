local pwd = require "src.fs.pwd"

describe("pwd", function ()
    it("gets the current directory", function ()
        local cwd = pwd.pwd()

        local contains = cwd:match("[/\\]")

        assert.truthy(contains)
    end)
end)