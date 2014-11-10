local lex = require "ltq.lex"

describe("lex", function()
   it("lexes empty string", function()
      assert.same({}, lex(""))
      assert.same({}, lex("   "))
   end)

   it("lexes names", function()
      assert.same({
         {tag = "name", offset = 1, value = "foo"},
         {tag = "name", offset = 5, value = "bar"}
      }, lex("foo bar"))
      assert.same({
         {tag = "name", offset = 1, value = "_"},
         {tag = "name", offset = 3, value = "baz_Q7"}
      }, lex("_ baz_Q7"))
   end)

   it("lexes keywords", function()
      assert.same({
         {tag = "true", offset = 1},
         {tag = "and", offset = 6},
         {tag = "false", offset = 10},
         {tag = "or", offset = 16},
         {tag = "not", offset = 19},
         {tag = "nil", offset = 23}
      }, lex("true and false or not nil"))
   end)

   it("lexes operators", function()
      assert.same({
         {tag = ".", offset = 1},
         {tag = "?", offset = 2},
         {tag = "+", offset = 3},
         {tag = "-", offset = 4},
         {tag = "*", offset = 5},
         {tag = "/", offset = 6},
         {tag = "//", offset = 8},
         {tag = "..", offset = 11},
         {tag = "==", offset = 14},
         {tag = "~=", offset = 17},
         {tag = "<", offset = 20},
         {tag = "<=", offset = 22},
         {tag = ">", offset = 25},
         {tag = ">=", offset = 27}
      }, lex(".?+-*/ // .. == ~= < <= > >="))
   end)

   it("lexes numbers", function()
      assert.same({
         {tag = "number", offset = 1, value = 1},
         {tag = "number", offset = 3, value = 2},
         {tag = "number", offset = 6, value = 0.4},
         {tag = "number", offset = 9, value = 120},
         {tag = "number", offset = 15, value = 12},
         {tag = "number", offset = 22, value = 0.12},
      }, lex("1 2. .4 1.2e2 1.2E+1 1.2e-1"))
   end)

   it("lexes strings", function()
      assert.same({
         {tag = "string", offset = 1, value = ""},
         {tag = "string", offset = 4, value = ""},
         {tag = "string", offset = 7, value = "foo"},
         {tag = "string", offset = 13, value = "bar"},
         {tag = "string", offset = 19, value = '"'},
         {tag = "string", offset = 23, value = "'"},
         {tag = "string", offset = 27, value = "\'\"\\"},
         {tag = "string", offset = 36, value = "line1\nline2"}
      }, lex([["" '' "foo" 'bar' '"' "'" "\'\"\\" "line1\nline2"]]))
   end)
end)
