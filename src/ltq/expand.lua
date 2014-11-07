local macros = require "ltq.macros"
local utils = require "ltq.utils"

-- Returns node with all macros expanded.
local function expand(node)
   if node.tag == "Literal" then
      return {tag = "Func",
         node[1]
      }
   end

   assert(node.tag == "Spec")

   for i = 2, #node do
      node[i] = expand(node[i])
   end

   return macros[node[1]](utils.unpack(node, 2))
end

return expand
