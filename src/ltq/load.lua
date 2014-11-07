local env = {}

function env.sort(t, key)
   local t2 = {}

   for i = 1, #t do
      t2[i] = t[i]
   end

   table.sort(t2, key)
   return t2
end

-- FIXME: this should be in utils module.

local load_string

if _VERSION:find("5.1") then
   load_string = loadstring
else
   load_string = load
end

-- Returns Lua code which assumes env is passed as vararg and unpacks it into local variables.
local function gen_env_unpaker()
   local buf = {"local env = ..."}

   for name in pairs(env) do
      buf[#buf + 1] = "local " .. name .. " = env." .. name
   end

   return table.concat(buf, "\n")
end

-- Takes compiled source of a function, returns loaded Lua function.
-- TODO: provide chunk name.
local function load(fsrc)
   local loader_src = gen_env_unpaker() .. "\nreturn " .. fsrc .. "\n"
   local loader = assert(load_string(loader_src))
   return assert(loader(env))
end

return load
