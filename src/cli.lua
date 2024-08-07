local ArgParse = require("lib.argparse")
local log      = require("lib.log")

local Bundler  = require("src.Bundler")
local uuidgen  = require("src.uuidgen")

require("src.seed_random")

local function cli()
    local parser = ArgParse("lua-bundler")

    -- parser
    --     :option("-c --config --config-file", "Read from a .lua or .json configuration file")

    -- parser
    --     :option("-m --map", "Remap a given file - <in> <out>"):count("*"):args(2)

    -- TODO FIXME this shit!
    parser
        :option("-p --publicdir", "Set the directory to copy LICENSE, README, etc from to outdir")

    parser
        :option("-l --library", "Add a library that is globally available in the target distribution of lua")
        :count("*")

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
    local libraries = args.library
    local public = args.publicdir

    local src = args.indir
    local dest = args.outdir

    -- print(uid)
    -- print(table.concat(libraries, " "))
    -- print(public)
    -- print(src, dest)

    local bundler = Bundler({
        src = src,
        dest = dest,

        uid = uid,

        libraries = libraries
    })

    bundler:run()
end

return cli
