local utils = require "ltq.utils"

local env = {}

function env.sort(t, key)
   local t2 = {}

   for i = 1, #t do
      t2[i] = t[i]
   end

   table.sort(t2, key)
   return t2
end

-- Returns Lua code which assumes env is passed as vararg and unpacks it into local variables.
local function gen_env_unpacker()
   local buf = {"local env = ..."}

   for name in pairs(env) do
      buf[#buf + 1] = "local " .. name .. " = env." .. name
   end

   return table.concat(buf, "\n")
end

-- Takes compiled source of a function, returns loaded Lua function.
-- TODO: provide chunk name.
local function load(fsrc)
   local loader_src = gen_env_unpacker() .. "\nreturn " .. fsrc .. "\n"
   local loader = assert(utils.loadstring(loader_src))
   return assert(loader(env))
end

return load
