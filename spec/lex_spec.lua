local lex = require "ltq.lex"

describe("lex", function()
   it("lexes empty string", function()
      assert.same({}, lex(""))
      assert.same({}, lex("   "))
   end)

   it("lexes names", function()
      assert.same({
         {tag = "name", offset = 1, "foo"},
         {tag = "name", offset = 5, "bar"}
      }, lex("foo bar"))
      assert.same({
         {tag = "name", offset = 1, "_"},
         {tag = "name", offset = 3, "baz_Q7"}
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
         {tag = "number", offset = 1, 1},
         {tag = "number", offset = 3, 2},
         {tag = "number", offset = 6, 0.4},
         {tag = "number", offset = 9, 120},
         {tag = "number", offset = 15, 12},
         {tag = "number", offset = 22, 0.12},
      }, lex("1 2. .4 1.2e2 1.2E+1 1.2e-1"))
   end)

   it("lexes strings", function()
      assert.same({
         {tag = "string", offset = 1, ""},
         {tag = "string", offset = 4, ""},
         {tag = "string", offset = 7, "foo"},
         {tag = "string", offset = 13, "bar"},
         {tag = "string", offset = 19, '"'},
         {tag = "string", offset = 23, "'"},
         {tag = "string", offset = 27, "\'\"\\"},
         {tag = "string", offset = 36, "line1\nline2"}
      }, lex([["" '' "foo" 'bar' '"' "'" "\'\"\\" "line1\nline2"]]))
   end)
end)
