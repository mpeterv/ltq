local utils = require "ltq.utils"

local lex = {}

local function location(entity, doffset)
   return {
      line = entity.line,
      offset = entity.offset + (doffset or 0),
      line_offset = entity.line_offset
   }
end

-- Can also be called as lex.error(state, msg)
function lex.error(state, loc, msg)
   if not msg then
      msg = loc
      loc = state
   end

   local column = loc.offset - loc.line_offset + 1
   local loc_as_str = ("%s:%d:%d"):format(state.chunkname, loc.line, column)
   local src_hint

   if loc.line_offset == #state.src + 1 then
      src_hint = " near EOF"
   else
      local src_line = state.src:match("[^\n]*", loc.line_offset)
      local caret_space = (" "):rep(column - 1)
      src_hint = ("\n    %s\n    %s^"):format(src_line, caret_space)
   end

   error(("%s: %s%s"):format(loc_as_str, msg, src_hint), 0)
end

function lex.assert(v, ...)
   return v or lex.error(...)
end

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

local function skip_char(lstate)
   local char = lstate.char
   lstate.offset = lstate.offset + 1
   lstate.char = lstate.src:sub(lstate.offset, lstate.offset)

   if is_newline(char) then
      lstate.line = lstate.line + 1

      if is_newline(lstate.char) and lstate.char ~= char then
         lstate.offset = lstate.offset + 1
         lstate.char = lstate.src:sub(lstate.offset, lstate.offset)
      end
      
      lstate.line_offset = lstate.offset
   end
end

local function test_char(lstate, c)
   if lstate.char == c then
      skip_char(lstate)
      return true
   else
      return false
   end
end

-- FIXME: does not load hexadecimal numbers.
-- Called after the first character has been skipped.
local function lex_number(lstate)
   local start_loc = location(lstate, -1)

   while not at_eof(lstate) do
      if test_char(lstate, "e") or test_char(lstate, "E") then
         if not test_char(lstate, "-") then
            test_char(lstate, "+")
         end
      end

      test_char(lstate, ".")

      if is_num(lstate.char) then
         skip_char(lstate)
      else
         break
      end
   end

   local number_as_string = lstate.src:sub(start_loc.offset, lstate.offset - 1)
   return "number", lex.assert(tonumber(number_as_string), lstate, start_loc, "malformed number")
end

-- Called after the first character has been skipped.
local function lex_ident(lstate)
   local start_offset = lstate.offset - 1

   while not at_eof(lstate) and is_alphanum(lstate.char) do
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
   local start_loc = location(lstate, -1)
   local buf = {}
   local chunk_start = lstate.offset

   while not test_char(lstate, quote) do
      lex.assert(not at_eof(lstate), lstate, start_loc, "unfinished string")
      lex.assert(not is_newline(lstate.char), lstate, start_loc, "unfinished string")

      if test_char(lstate, "\\") then
         buf[#buf + 1] = lstate.src:sub(chunk_start, lstate.offset - 2)
         lex.assert(not at_eof(lstate), lstate, start_loc, "unfinished string")
         local esc = lex.assert(escapes[lstate.char], lstate, location(lstate, -1), "invalid escape sequence")
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
   local c = lstate.char
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
      elseif is_num(lstate.char) then
         return lex_number(lstate, c)
      end
   elseif c == "/" then
      if test_char(lstate, "/") then
         return "//"
      end
   end

   return c
end

local function lex_(src, chunkname)
   local tokens = {}
   local lstate = {
      src = src,
      chunkname = chunkname,
      char = src:sub(1, 1),
      offset = 1,
      line = 1,
      line_offset = 1
   }

   while not at_eof(lstate) do
      if is_whitespace(lstate.char) then
         skip_char(lstate)
      else
         local offset = lstate.offset
         local line = lstate.line
         local line_offet = lstate.line_offset
         local tag, value = lex_next(lstate)
         tokens[#tokens + 1] = {
            tag = tag,
            value = value,
            offset = offset,
            line = line,
            line_offset = line_offet
         }
      end
   end

   tokens[#tokens + 1] = {
      tag = "EOF",
      offset = lstate.offset,
      line = lstate.line,
      line_offset = lstate.line_offset
   }

   return tokens
end

-- Returns array of tokens or nil, error.
-- A token is a table {tag = tag, value = [value], offest = offset, line = line, line_offset = line_offset}.
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
function lex.lex(src, chunkname)
   chunkname = chunkname or "ltq"
   local ok, res = pcall(function() return lex_(src, chunkname) end)

   if ok then
      return res
   else
      return nil, res
   end
end

return lex
