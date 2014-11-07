local builtins = require "ltq.builtins"
local utils = require "ltq.utils"

-- Returns loadable representation of value.
local function repr(v)
   if v == nil then
      return "nil"
   elseif v == true then
      return "true"
   elseif v == false then
      return "false"
   elseif type(v) == "number" then
      if v == 1/0 then
         return "1/0"
      elseif v == -1/0 then
         return -1/0
      elseif v ~= v then
         return "0/0"
      else
         -- FIXME: this may lose precision.
         return tostring(v)
      end
   else
      assert(type(v) == "string")
      -- FIXME: this may be unreliable?
      return ("%q"):format(v)
   end
end

local function new_env()
   local env = {
      last_var = 0
   }

   function env:var()
      self.last_var = self.last_var + 1
      return "v" .. tostring(self.last_var)
   end

   -- Returns nested arrays of strings represening statement and expression parts of node.
   function env:compile(node, var)
      if type(node) ~= "table" then
         return {}, {repr(node)}
      elseif node.tag == "X" then
         return {}, {var}
      elseif node.tag == "Func" then
         var = self:var()
         local stat, expr = self:compile(node[1], var)
         return {}, {"function(", var, ")\n", stat, "return ", expr, "\nend"}
      elseif node.tag == "Let" then
         local rhs_stat, rhs_expr = self:compile(node[2], var)
         var = self:var()
         local lhs_stat, lhs_expr = self:compile(node[1], var)
         return {rhs_stat, "local ", var, " = ", rhs_expr, "\n", lhs_stat}, lhs_expr
      else
         assert(node.tag == "Builtin")
         return builtins[node[1]](self, var, utils.unpack(node, 2))
      end
   end

   return env
end

local function compile(node)
   local env = new_env()
   local _, expr_rope = env:compile(node)
   local flat = utils.flatten(expr_rope)
   return table.concat(flat)
end

return compile
