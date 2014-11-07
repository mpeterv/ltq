-- Builtins are represented by functions taking compilation environment, varible name and arguments
-- and returning nested arrays of strings representing statement and expression parts of result.
local builtins = {}

-- Returns a builtin for a prefix unary opator.
local function unop(op)
   return function(env, var, a)
      local a_stat, a_expr = env:compile(a, var)
      return a_stat, {op, "(", a_expr, ")"}
   end
end

-- Returns a builtin for an infix binary operator.
local function binop(op)
   return function(env, var, a, b)
      local a_stat, a_expr = env:compile(a, var)
      local b_stat, b_expr = env:compile(b, var)
      return {a_stat, b_stat}, {"(", a_expr, ")", op, "(", b_expr, ")"}
   end
end

builtins.unm = unop("-")
builtins.add = binop("+")
builtins.sub = binop("-")
builtins.mul = binop("*")
builtins.div = binop("/")
builtins.pow = binop("^")
builtins.mod = binop("%")

builtins.len = unop("#")
builtins.cat = binop("..")

builtins.eq = binop("==")
builtins.ne = binop("~=")
builtins.lt = binop("<")
builtins.lte = binop("<=")
builtins.gt = binop(">")
builtins.gte = binop(">=")

builtins["not"] = unop("not")
builtins["and"] = binop("and")
builtins["or"] = binop("or")

function builtins.index(env, var, a, b)
   local a_stat, a_expr = env:compile(a, var)
   local b_stat, b_expr = env:compile(b, var)
   return {a_stat, b_stat}, {"(", a_expr, ")[", b_expr, "]"}
end

function builtins.map(env, var, f, a)
   assert(f.tag == "Func")
   local fb = f[1]
   local arr_var = env:var()
   local res_var = env:var()
   local i_var = env:var()
   local item_var = env:var()
   local arr_stat, arr_expr = env:compile(a, var)
   local fb_stat, fb_expr = env:compile(fb, item_var)
   return {arr_stat,
      "local ", arr_var, " = ", arr_expr, "\n",
      "local ", res_var, " = {}\n",
      "for ", i_var, " = 1, #", arr_var, " do\n",
         "local ", item_var, " = ", arr_var, "[", i_var, "]\n",
         fb_stat,
         res_var, "[", i_var, "] = ", fb_expr, "\n",
      "end\n"
   }, {res_var}
end

return builtins
