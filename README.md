

# Lua-bundler

A command-line application to turn lua project directories into portable, self-contained libraries, featuring their own dependencies. `src/init.lua` also provides a Bundler class if you wish to use the functionality in a Lua project.

## Command-line options

`lua src/init.lua --help`

```
Usage: lua-bundler [-i <ignore>] [--preserve <comments|annotations>]
       [--uid <uid>] [--log-level <log_level>] [-h] <indir> <outdir>

Arguments:
   indir
   outdir

Options:
         -i <ignore>,    Add a library that is globally available in the target distribution of lua
   --ignore <ignore>
   --preserve <comments|annotations>
                         Preserve lua-language-server annotations or all comments
   --uid <uid>           Set the unique identifier of this bundle. Defaults to uuidgen
   --log-level <log_level>
                         Set the program's log level. Default = warn
   -h, --help            Show this help message and exit.
```