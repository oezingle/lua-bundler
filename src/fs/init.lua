
local fs = {
    ls = require("src.fs.list").ls,
    mkdir = require("src.fs.mkdir").mkdir,
    mkdir_p = require("src.fs.mkdir_p"),
    cp = require("src.fs.cp"),
    is_dir = require("src.fs.is_dir"),
    exists = require("src.fs.exists"),

    read = require("src.fs.read"),
    write = require("src.fs.write"),

    pwd = require("src.fs.pwd").pwd,
    is_windows = require("src.fs.is_windows"),
}

return fs