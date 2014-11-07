local utils = require "ltq.utils"

-- Macros are represented by functions which take parameters(functions) and return expanded macro.
local macros = {}

-- TODO: resolve macros using number of parameters.
-- TODO: vararg index macro and builtin.
-- TODO: over-parameterization of simple macros.

local TVALUE = {}
local TFUNC = {}

local unop_sig = {TVALUE}
local binop_sig = {TVALUE, TVALUE}
local second_order_sig = {TFUNC, TVALUE}

-- Returns a macro for a builtin with given name and signature.
-- Signature is an array of TVALUE or TFUNC.
-- Builtin must take more than one value argument or one value argument (last).
local function bmacro(bname, sig)
   local nvalues = 0

   for i = 1, #sig do
      if sig[i] == TVALUE then
         nvalues = nvalues + 1
      else
         assert(sig[i] == TFUNC)
      end
   end

   local autoapply

   if nvalues > 1 then
      -- Macro expands to one-argument function, but builtin requires more values.
      -- Solution: apply paramaters to x to get arguments for the builtin.
      autoapply = true
   else
      assert(nvalues == 1)
      assert(sig[#sig] == TVALUE)
      autoapply = false
   end

   return function(...)
      local nparams = select("#", ...)

      if autoapply then
         -- Each parameter gives one argument for builtin.
         assert(nparams == #sig)
      else
         -- Each parameter gives one argument for builtin, last one is x.
         assert(nparams == #sig - 1)
      end

      local bargs = {}

      for i = 1, nparams do
         local param = select(i, ...)

         if sig[i] == TFUNC then
            bargs[i] = param
         else
            assert(autoapply)
            bargs[i] = {tag = "Call",
               param,
               {tag = "X"}
            }
         end
      end

      if not autoapply then
         bargs[#sig] = {tag = "X"}
      end

      return {tag = "Func",
         {tag = "Builtin",
            bname,
            utils.unpack(bargs)
         }
      }
   end
end

local function unmacro(bname)
   return bmacro(bname, unop_sig)
end

local function binmacro(bname)
   return bmacro(bname, binop_sig)
end

macros["`pipe`"] = function(f, g)
   return {tag = "Func",
      {tag = "Call",
         g,
         {tag = "Call",
            f,
            {tag = "X"}
         }
      }
   }
end

macros["`id`"] = function()
   return {tag = "Func",
      {tag = "X"}
   }
end

macros["`if`"] = bmacro("if", {TVALUE, TVALUE, TVALUE})

macros["`unm`"] = unmacro("unm")
macros["`add`"] = binmacro("add")
macros["`sub`"] = binmacro("sub")
macros["`mul`"] = binmacro("mul")
macros["`div`"] = binmacro("div")
macros["`pow`"] = binmacro("pow")
macros["`mod`"] = binmacro("mod")

macros["`len`"] = unmacro("len")
macros["`concat`"] = unmacro("concat")

macros["`eq`"] = binmacro("eq")
macros["`ne`"] = binmacro("ne")
macros["`lt`"] = binmacro("lt")
macros["`lte`"] = binmacro("lte")
macros["`gt`"] = binmacro("gt")
macros["`gte`"] = binmacro("gte")

macros["`not`"] = unmacro("not")
macros["`and`"] = binmacro("and")
macros["`or`"] = binmacro("or")

macros["`index`"] = binmacro("index")

macros["`map`"] = bmacro("map", second_order_sig)
macros["filter"] = bmacro("filter", second_order_sig)
macros["sort1"] = bmacro("sort2", second_order_sig)
macros["sort0"] = unmacro("sort1")

return macros
