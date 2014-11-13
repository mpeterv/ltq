local lex = require "ltq.lex"
local utils = require "ltq.utils"

local parse_expression

local function get_token(pstate, index)
   return pstate.tokens[index]
end

local function skip_token(pstate)
   local token = pstate.token
   pstate.token_index = pstate.token_index + 1
   pstate.token = get_token(pstate, pstate.token_index)
   return token
end

local token_representations = {
   EOF = "<eof>",
   name = "identifier",
   number = "number",
   string = "string"
}

local function token_to_string(tag)
   return token_representations[tag] or ("'" .. tag .. "'")
end

local function check_token(pstate, tag, msg)
   lex.assert(pstate.token.tag == tag, pstate, pstate.token, msg or (token_to_string(tag) .. " expected"))
end

local function check_and_skip_token(pstate, tag, msg)
   check_token(pstate, tag, msg)
   return skip_token(pstate)
end

local token_pairs = {
   ["("] = ")",
   ["{"] = "}",
   ["["] = "]"
}

local function match_token(pstate, opening_token)
   local msg
   local expectation = token_pairs[opening_token.tag]

   if opening_token.line ~= pstate.token.line then
      msg = ("%s expected (to close %s at line %d)"):format(
         token_to_string(expectation), token_to_string(opening_token.tag), opening_token.line
      )
   end

   check_and_skip_token(pstate, expectation, msg)
end

local function test_token(pstate, tag)
   if pstate.token.tag == tag then
      return skip_token(pstate)
   else
      return false
   end
end

local function lookahead_token(pstate)
   return get_token(pstate, pstate.token_index + 1)
end

local function quote(op)
   return "`" .. op .. "`"
end

local function spec(...)
   return {tag = "Spec", ...}
end

local function literal(value)
   return {tag = "Literal", value}
end

local function binop(operator, expr1, expr2)
   if type(operator) == "table" then
      -- It is the pseudo binary operator (? expr :).
      return spec("`if`", expr1, operator, expr2)
   else
      if operator == "map" then
         -- expr1 \ expr2 is syntax sugar for expr1 | \ expr2
         return spec("`pipe`", expr1, spec("`map`", expr2))
      else
         return spec(quote(operator), expr1, expr2)
      end
   end
end

local function check_name(pstate)
   check_token(pstate, "name")
   local res = pstate.token.value
   skip_token(pstate)
   return res
end

-- primary_expression ::= "." | "." name | "(" expression ")"
local function parse_primary_expression(pstate)
   if test_token(pstate, ".") then
      if pstate.token.tag == "name" then
         return spec("`index`", spec("`id`"), literal(check_name(pstate)))
      else
         return spec("`id`")
      end
   else
      local opening = check_and_skip_token(pstate, "(", "expected expression")
      local expression = parse_expression(pstate)
      match_token(pstate, opening)
      return expression
   end
end

-- suffixed_expression ::= primary_expression { "." name | "[" expression "]" }
local function parse_suffixed_expression(pstate)
   local primary_expression = parse_primary_expression(pstate)
   local index_chain = {primary_expression}

   while true do
      if test_token(pstate, ".") then
         local index = literal(check_name(pstate))
         index_chain[#index_chain + 1] = index
      elseif pstate.token.tag == "[" then
         local opening = skip_token(pstate)
         local index = parse_expression(pstate)
         match_token(pstate, opening)
         index_chain[#index_chain + 1] = index
      else
         break
      end
   end

   if #index_chain > 1 then
      return spec("`index`", utils.unpack(index_chain))
   else
      return primary_expression
   end
end

-- pair ::= expression | (name | "[" expression "]") "=" expression
local function parse_pair(pstate)
   local index

   if pstate.token.tag == "name" then
      if lookahead_token(pstate).tag == "=" then
         index = literal(check_name(pstate))
         skip_token(pstate)
      end
   elseif pstate.token.tag == "[" then
      local opening = skip_token(pstate)
      index = parse_expression(pstate)
      match_token(pstate, opening)
      check_and_skip_token(pstate, "=")
   end

   local value = parse_expression(pstate)
   return index, value
end

-- table ::= "{" [ pair { sep pair } [sep] ] "}"
-- sep ::= "," | ";"
local function parse_table(pstate)
   local opening = check_and_skip_token(pstate, "{")

   local parameters = {}
   local next_array_index = 1

   repeat
      if pstate.token.tag == "}" then
         break
      end

      local index, value = parse_pair(pstate)

      if not index then
         index = literal(next_array_index)
         next_array_index = next_array_index + 1
      end

      parameters[#parameters + 1] = index
      parameters[#parameters + 1] = value
   until not test_token(pstate, ",") and not test_token(pstate, ";")

   match_token(pstate, opening)
   return spec("`table`", utils.unpack(parameters))
end

-- macro ::= name | name "(" [expression {"," expression}] ")"
local function parse_macro(pstate)
   local name = check_name(pstate)
   local parameters = {}

   if pstate.token.tag == "(" then
      local opening = skip_token(pstate)

      if not test_token(pstate, ")") then
         repeat
            local parameter = parse_expression(pstate)
            parameters[#parameters + 1] = parameter
         until not test_token(pstate, ",")

         match_token(pstate, opening)
      end
   end

   return spec(name, utils.unpack(parameters))
end

local simple_tokens = utils.array_to_set({
   "nil", "true", "false", "number", "string", "{", "name", ".", "("
})

-- simple_expression ::= nil | true | false | number | string | table | macro | suffixed_expression
local function parse_simple_expression(pstate)
   if test_token(pstate, "nil") then
      return literal(nil)
   elseif test_token(pstate, "true") then
      return literal(true)
   elseif test_token(pstate, "false") then
      return literal(false)
   elseif pstate.token.tag == "number" or pstate.token.tag == "string" then
      local value = pstate.token.value
      skip_token(pstate)
      return literal(value)
   elseif pstate.token.tag == "{" then
      return parse_table(pstate)
   elseif pstate.token.tag == "name" then
      return parse_macro(pstate)
   else
      return parse_suffixed_expression(pstate)
   end
end

local unary_operators = {
   ["not"] = "not",
   ["-"] = "unm",
   ["#"] = "len",
   ["\\"] = "map"
}

local unary_priority = 12

local binary_operators = {
   ["+"] = "add", ["-"] = "sub",
   ["*"] = "mul", ["%"] = "mod",
   ["/"] = "div", ["//"] = "idiv",
   ["^"] = "pow",
   [".."] = "concat",
   ["~="] = "neq", ["=="] = "eq",
   ["<"] = "lt", ["<="] = "lte",
   [">"] = "gt", [">="] = "gte",
   ["and"] = "and", ["or"] = "or",
   ["|"] = "pipe", ["\\"] = "map"
}

local add_priority = {left = 10, right = 10}
local mul_priority = {left = 11, right = 11}
local eq_priority = {left = 7, right = 7}
local pipe_priority = {left = 1, right = 1}
local ternary_priority = {left = 4, right = 3}

local binary_priorities = {
   add = add_priority, sub = add_priority,
   mul = mul_priority, mod = mul_priority,
   div = mul_priority, idiv = mul_priority,
   pow = {left = 14, right = 13},
   concat = {left = 9, right = 8},
   neq = eq_priority, eq = eq_priority,
   lt = eq_priority, lte = eq_priority,
   gt = eq_priority, gte = eq_priority,
   ["and"] = {left = 6, right = 6},
   ["or"] = {left = 5, right = 5},
   pipe = pipe_priority, map = pipe_priority
}

-- subexpression ::= (simple_expression | unop [subexpression]) { binop' subexpression }
-- binop' ::= binop | "?" subexpression ":"
local function parse_subexpression(pstate, limit)
   local expression
   local unary_operator = unary_operators[pstate.token.tag]

   if unary_operator then
      skip_token(pstate)

      -- `unop op expr` is ambigious when `op` can be binary or unary (E.g. "-").
      -- Parse it as `(unop) op (expr)`.

      if simple_tokens[pstate.token.tag] or
            (unary_operators[pstate.token.tag] and not binary_operators[pstate.token.tag]) then
         local unary_operand = parse_subexpression(pstate, unary_priority)
         expression = spec(quote(unary_operator), unary_operand)
      else
         expression = spec(quote(unary_operator))
      end
   else
      expression = parse_simple_expression(pstate)
   end

   -- Expand while operators have priorities higher than limit.
   while true do
      local binary_operator
      local priority

      if pstate.token.tag == "?" and limit < ternary_priority.left then
         -- ("?" expression ":") is treated as a binary operator.
         skip_token(pstate)
         binary_operator = parse_subexpression(pstate, ternary_priority.right)
         check_token(pstate, ":")
         priority = ternary_priority
      else
         binary_operator = binary_operators[pstate.token.tag]
         priority = binary_priorities[binary_operator]
      end

      if not binary_operator or priority.left <= limit then
         break
      end

      skip_token(pstate)  -- Skip the operator.
      -- Read subexpression with higher priority.
      local subexpression = parse_subexpression(pstate, priority.right)
      expression = binop(binary_operator, expression, subexpression)
   end

   return expression
end

function parse_expression(pstate)
   return parse_subexpression(pstate, 0)
end

local function parse_(src, chunkname, tokens)
   local pstate = {
      src = src,
      chunkname = chunkname,
      tokens = tokens,
      token_index = 0
   }

   skip_token(pstate)
   local res = parse_expression(pstate)
   check_token(pstate, "EOF")
   return res
end

-- Returns ast or nil, error. FIXME: actually return nil, error.
-- ast is a table {tag = tag, ast*}.
-- parse produces ast with tags "Spec" (macro specialization) and "Literal" (which carry literal value as first item).
local function parse(src, chunkname)
   chunkname = chunkname or "ltq"
   local tokens, err = lex.lex(src, chunkname)

   if not tokens then
      return nil, err
   end

   local ok, res = pcall(function() return parse_(src, chunkname, tokens) end)

   if ok then
      return res
   else
      return nil, res
   end
end

return parse
