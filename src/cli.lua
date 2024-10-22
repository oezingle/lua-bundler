local ArgParse = require("lib.argparse")
local log      = require("lib.log")

local Bundler  = require("src.Bundler")
local uuidgen  = require("src.uuidgen")

require("src.seed_random")

local function cli()
    local parser = ArgParse("lua-bundler")


    -- parser
    --     :option("-c --config --config-file", "Read from a .lua or .json configuration file")

    -- TODO this option is a bit funky. might remove in future.
    parser
        :option("-p --publicdir", "[DEPRECATED] Set the directory to copy LICENSE, README, etc from to outdir")
        :hidden(true)

    parser
        :option("-l --library", "[DEPRECATED] Add a library that is globally available in the target distribution of lua")
        :count("*")
        :hidden(true)

    parser
        :option("-i --ignore", "Add a library that is globally available in the target distribution of lua")
        :count("*")

    parser
        :option("--preserve", "Preserve lua-language-server annotations or all comments")
        :argname("<comments|annotations>")
        -- :choices({"comments", "annotations"})

    --[[
    parser
        :option("-I --include", "Add a library that is stored at another path that you wish to bundle")
        :count("*")
        :args(2)
        :argname({ "path", "modname" })
    ]]

    parser
        :option("--uid", "Set the unique identifier of this bundle. Defaults to uuidgen")

    parser
        :option("--log-level", "Set the program's log level. Default = warn")
    -- :choices({ "trace", "debug", "info", "warn", "error", "fatal"})

    parser:argument("indir")
    parser:argument("outdir")

    local args = parser:parse()

    log.level = args.log_level or "warn"

    local uid = args.uid or uuidgen()
    local ignore = args.ignore

    -- copy from deprecated --library flag
    if args.publicdir then
        log.warn("--publicdir option is deprecated")
    end
    if #args.library > 0 then
        log.warn("--library option is deprecated. Use --ignore instead")
    end
    for _, lib in ipairs(args.library) do
        table.insert(ignore, lib)
    end

    local public = args.publicdir
    
    local preserve = args.preserve

    if preserve and preserve ~= "comments" and preserve ~= "annotations" then
        print("Error: expected preserve to be either \"comments\" or \"annotations\"")

        os.exit(1)
    end

    local src = args.indir
    local dest = args.outdir


    --[[
    local include = {}
    for tuple in pairs(args.include) do
        local path = tuple[1]
        local modname = tuple[2]

        table.insert(include, { path = path, modname = modname })
    end
]]

    local bundler = Bundler({
        src = src,
        dest = dest,

        uid = uid,

        ignore = ignore,
        -- include = include,
        preserve = preserve,

        public = public,
    })

    bundler:run()
end

return cli
