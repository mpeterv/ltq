local utils = require "ltq.utils"

local keywords = utils.array_to_set({
   "and", "or", "not", "nil", "true", "false"
})

local function is_alpha(c)
   return ("a" <= c and c <= "z") or ("A" <= c and c <= "Z") or c == "_"
end

local function is_num(c)
   return "0" <= c and c <= "9"
end

local function is_alphanum(c)
   return is_alpha(c) or is_num(c)
end

local function is_newline(c)
   return c == "\n" or c == "\r"
end

local function is_whitespace(c)
   return c == " " or is_newline(c) or c == "\f" or c == "\t" or c == "\v"
end

local escapes = {
   a = "\a",
   b = "\b",
   f = "\f",
   n = "\n",
   r = "\r",
   t = "\t",
   v = "\v",
   ["\\"] = "\\",
   ["'"] = "'",
   ['"'] = '"'
}

local function at_eof(lstate)
   return lstate.offset > #lstate.src
end

local function cur_char(lstate)
   return lstate.src:sub(lstate.offset, lstate.offset)
end

local function skip_char(lstate)
   lstate.offset = lstate.offset + 1
end

local function test_char(lstate, c)
   if cur_char(lstate) == c then
      skip_char(lstate)
      return true
   else
      return false
   end
end

-- FIXME: does not load hexadecimal numbers.
-- Called after the first character has been skipped.
local function lex_number(lstate)
   local start_offset = lstate.offset - 1

   while not at_eof(lstate) do
      if test_char(lstate, "e") or test_char(lstate, "E") then
         if not test_char(lstate, "-") then
            test_char(lstate, "+")
         end
      end

      test_char(lstate, ".")

      if is_num(cur_char(lstate)) then
         skip_char(lstate)
      else
         break
      end
   end

   local number_as_string = lstate.src:sub(start_offset, lstate.offset - 1)
   return "number", assert(tonumber(number_as_string), "malformed number")
end

-- Called after the first character has been skipped.
local function lex_ident(lstate)
   local start_offset = lstate.offset - 1

   while not at_eof(lstate) and is_alphanum(cur_char(lstate)) do
      skip_char(lstate)
   end

   local ident = lstate.src:sub(start_offset, lstate.offset - 1)

   if keywords[ident] then
      return ident
   else
      return "name", ident
   end
end

-- FIXME: does not load non-primitive escape sequences.
-- Called after the opening quote has been skipped.
local function lex_string(lstate, quote)
   local buf = {}
   local chunk_start = lstate.offset

   while not test_char(lstate, quote) do
      assert(not at_eof(lstate), "unfinished string")
      assert(not is_newline(cur_char(lstate)), "unfinished string")

      if test_char(lstate, "\\") then
         buf[#buf + 1] = lstate.src:sub(chunk_start, lstate.offset - 2)
         assert(not at_eof(lstate), "unfinished string")
         local esc = assert(escapes[cur_char(lstate)], "invalid escape sequence")
         skip_char(lstate)
         buf[#buf + 1] = esc
         chunk_start = lstate.offset
      else
         skip_char(lstate)
      end
   end

   buf[#buf + 1] = lstate.src:sub(chunk_start, lstate.offset - 2)
   return "string", table.concat(buf)
end

-- Returns tag and value for next token, moves offset to position after its end.
local function lex_next(lstate)
   local c = cur_char(lstate)
   skip_char(lstate)

   if is_num(c) then
      return lex_number(lstate)
   elseif is_alpha(c) then
      return lex_ident(lstate)
   elseif c == "'" or c == '"' then
      return lex_string(lstate, c)
   elseif c == "=" then
      if test_char(lstate, "=") then
         return "=="
      end
   elseif c == "<" then
      if test_char(lstate, "=") then
         return "<="
      end
   elseif c == ">" then
      if test_char(lstate, "=") then
         return ">="
      end
   elseif c == "~" then
      if test_char(lstate, "=") then
         return "~="
      end
   elseif c == "." then
      if test_char(lstate, ".") then
         return ".."
      elseif is_num(cur_char(lstate)) then
         return lex_number(lstate, c)
      end
   elseif c == "/" then
      if test_char(lstate, "/") then
         return "//"
      end
   end

   return c
end

-- Returns array of tokens or nil, error. FIXME: actually return nil, error.
-- A token is a table {[value], tag = tag, offest = offset}.
-- tag is the token body itself for primitive tokens(E.g. ".") or "name", "string" or "number".
-- value is the name as string for "name" tokens, and value of literal for "string" and "number" tokens.
-- Multi-character primitive tokens are:
--    "==", "~=",
--    "<=", ">=",
--    "..", "//",
--    "and", "or", "not",
--    "nil", "true", "false".
-- FIXME: does not support long strings.
-- FIXME: does not support comments.
local function lex(src)
   local tokens = {}
   local lstate = {
      src = src,
      offset = 1
   }

   while not at_eof(lstate) do
      if is_whitespace(cur_char(lstate)) then
         skip_char(lstate)
      else
         local offset = lstate.offset
         local tag, value = lex_next(lstate)
         tokens[#tokens + 1] = {
            tag = tag,
            offset = offset,
            value
         }
      end
   end

   return tokens
end

return lex
