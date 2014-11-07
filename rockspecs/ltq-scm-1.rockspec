package = "ltq"
version = "scm-1"
source = {
   url = "git://github.com/mpeterv/ltq.git"
}
description = {
   summary = "TODO",
   detailed = [[
TODO
]],
   homepage = "https://github.com/mpeterv/ltq",
   license = "MIT/X11"
}
dependencies = {
   "lua >= 5.1, < 5.4"
}
build = {
   type = "builtin",
   modules = {
      ["ltq.inline"] = "src/ltq/inline.lua",
      ["ltq.builtins"] = "src/ltq/builtins.lua",
      ["ltq.compile"] = "src/ltq/compile.lua",
      ["ltq.load"] = "src/ltq/load.lua",
      ["ltq.utils"] = "src/ltq/utils.lua"
   },
   copy_directories = {"spec"}
}
