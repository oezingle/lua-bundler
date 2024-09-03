local Bundler = require("src.Bundler")

require("lib.log").level = "error"

describe("Bundler", function()
    describe("is_ignored", function()
        local bundler = Bundler.create({
            src = "",
            dest = "",
            uid = "fake",
            ignore = {
                "ext"
            }
        })

        it("correctly matches for exact calls", function ()
            assert.truthy(bundler:is_ignored("ext"))
        end)

        it("correctly matches for sublibraries", function ()
            assert.truthy(bundler:is_ignored("ext.op"))
        end)
    end)
end)
