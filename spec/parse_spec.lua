local parse = require "ltq.parse"
local lex = require "ltq.lex"

describe("parse", function()
   it("parses identity", function()
      assert.same({tag = "Spec", "`id`"}, parse(lex(".")))
   end)

   it("parses literal expressions", function()
      assert.same({tag = "Literal", 1}, parse(lex("1")))
      assert.same({tag = "Literal", false}, parse(lex("(false)")))
   end)

   it("parses nullary macros", function()
      assert.same({tag = "Spec", "`len`"}, parse(lex("#")))
      assert.same({tag = "Spec", "`unm`"}, parse(lex("((-))")))
      assert.same({tag = "Spec", "sort"}, parse(lex("sort")))
      assert.same({tag = "Spec", "sort"}, parse(lex("sort()")))
      assert.same({tag = "Spec", "type"}, parse(lex("(type)")))
   end)

   it("parses unary macros", function()
      assert.same({tag = "Spec", "`len`", {tag = "Literal", "foo"}}, parse(lex("#'foo'")))
      assert.same({tag = "Spec", "`unm`", {tag = "Spec", "`len`"}}, parse(lex("-#")))
      assert.same({tag = "Spec", "sort", {tag = "Spec", "`len`"}}, parse(lex("sort(#)")))
      assert.same({tag = "Spec", "sort", {tag = "Spec", "type"}}, parse(lex("sort(type)")))
   end)

   it("parses multi-parameter macros", function()
      assert.same({tag = "Spec", "foo",
         {tag = "Spec", "bar"},
         {tag = "Literal", 2},
         {tag = "Spec", "baz"}
      }, parse(lex("foo(bar(), 2, baz)")))
   end)

   it("parses indexing macros", function()
      assert.same({tag = "Spec", "`index`",
         {tag = "Spec", "`id`"},
         {tag = "Literal", "foo"}
      }, parse(lex(".foo")))
      assert.same({tag = "Spec", "`index`",
         {tag = "Spec", "`id`"},
         {tag = "Literal", 1}
      }, parse(lex(".[1]")))
      assert.same({tag = "Spec", "`index`",
         {tag = "Spec", "`index`",
            {tag = "Spec", "`id`"},
            {tag = "Literal", "foo"}
         },
         {tag = "Literal", 1}
      }, parse(lex(".foo[1]")))
      assert.same({tag = "Spec", "`index`",
         {tag = "Spec", "`id`"},
         {tag = "Literal", 1},
         {tag = "Literal", "foo"},
         {tag = "Spec", "`index`",
            {tag = "Spec", "`id`"},
            {tag = "Literal", "bar"}
         }
      }, parse(lex(".[1].foo[.bar]")))
      assert.same({tag = "Spec", "`index`",
         {tag = "Spec", "`index`",
            {tag = "Spec", "`id`"},
            {tag = "Literal", 1},
            {tag = "Spec", "`index`",
               {tag = "Spec", "`id`"},
               {tag = "Literal", 2}
            }
         },
         {tag = "Literal", "foo"}
      }, parse(lex("(.[1][.[2]]).foo")))
   end)

   it("parses table constructing macros", function()
      assert.same({tag = "Spec", "`table`"}, parse(lex("{}")))
      assert.same({tag = "Spec", "`table`",
         {tag = "Literal", 1},
         {tag = "Literal", 1}
      }, parse(lex("{1}")))
      assert.same({tag = "Spec", "`table`",
         {tag = "Literal", 1},
         {tag = "Literal", 1}
      }, parse(lex("{1,}")))
      assert.same({tag = "Spec", "`table`",
         {tag = "Literal", 1},
         {tag = "Spec", "type"},
         {tag = "Literal", 2},
         {tag = "Spec", "`table`"},
         {tag = "Literal", 3},
         {tag = "Literal", 5},
         {tag = "Literal", 4},
         {tag = "Spec", "`len`"}
      }, parse(lex("{type, {}, 5, #}")))
      assert.same({tag = "Spec", "`table`",
         {tag = "Literal", 1},
         {tag = "Spec", "`len`"},
         {tag = "Literal", "type"},
         {tag = "Spec", "type"},
         {tag = "Literal", 2},
         {tag = "Literal", 5}
      }, parse(lex("{#, type = type, 5}")))
      assert.same({tag = "Spec", "`table`",
         {tag = "Spec", "`table`"},
         {tag = "Spec", "`table`"},
         {tag = "Spec", "`index`",
            {tag = "Spec", "`id`"},
            {tag = "Literal", 1}
         },
         {tag = "Spec", "`index`",
            {tag = "Spec", "`id`"},
            {tag = "Literal", 2}
         }
      }, parse(lex("{[{}] = {}; [.[1]] = .[2];}")))
   end)

   it("parses infix operators", function()
      assert.same({tag = "Spec", "`add`",
         {tag = "Literal", 1},
         {tag = "Literal", 2}
      }, parse(lex("1 + 2")))
      assert.same({tag = "Spec", "`add`",
         {tag = "Spec", "`unm`",
            {tag = "Literal", 1}
         },
         {tag = "Literal", 2}
      }, parse(lex("- 1 + 2")))
      assert.same({tag = "Spec", "`add`",
         {tag = "Spec", "`index`",
            {tag = "Spec", "`id`"},
            {tag = "Literal", "foo"}
         },
         {tag = "Spec", "`mul`",
            {tag = "Spec", "`index`",
               {tag = "Spec", "`id`"},
               {tag = "Literal", "bar"}
            },
            {tag = "Literal", 4}
         }
      }, parse(lex(".foo + .bar * 4")))
      assert.same({tag = "Spec", "`pow`",
         {tag = "Spec", "a"},
         {tag = "Spec", "`pow`",
            {tag = "Spec", "b"},
            {tag = "Spec", "c"}
         }
      }, parse(lex("a^b^c")))
      assert.same({tag = "Spec", "`concat`",
         {tag = "Spec", "a"},
         {tag = "Spec", "`concat`",
            {tag = "Spec", "b"},
            {tag = "Spec", "c"}
         }
      }, parse(lex("a..b..c")))
      {tag = "Op", "or",
                        {tag = "Op", "and",
                           {tag = "Op", "eq",
                              {tag = "Id", "a"},
                              {tag = "Id", "b"}
                           },
                           {tag = "Op", "eq",
                              {tag = "Id", "c"},
                              {tag = "Id", "d"}
                           }
                        },
                        {tag = "Op", "ne",
                           {tag = "Id", "e"},
                           {tag = "Id", "f"}
                        }
                     }
      assert.same({tag = "Spec", "`or`",
         {tag = "Spec", "`and`",
            {tag = "Spec", "`eq`",
               {tag = "Spec", "a"},
               {tag = "Spec", "b"}
            },
            {tag = "Spec", "`eq`",
               {tag = "Spec", "c"},
               {tag = "Spec", "d"}
            }
         },
         {tag = "Spec", "`neq`",
            {tag = "Spec", "e"},
            {tag = "Spec", "f"}
         }
      }, parse(lex("a == b and c == d or e ~= f")))
   end)

   it("parses ternary operator", function()
      assert.same({tag = "Spec", "`if`",
         {tag = "Spec", "`eq`",
            {tag = "Spec", "type"},
            {tag = "Literal", "table"}
         },
         {tag = "Spec", "`index`",
            {tag = "Spec", "`id`"},
            {tag = "Literal", "value"}
         },
         {tag = "Spec", "`id`"}
      }, parse(lex("type == 'table' ? .value : .")))
      assert.same({tag = "Spec", "`if`",
         {tag = "Spec", "a"},
         {tag = "Spec", "b"},
         {tag = "Spec", "`if`",
            {tag = "Spec", "c"},
            {tag = "Spec", "d"},
            {tag = "Spec", "e"}
         }
      }, parse(lex("a ? b : c ? d : e")))
      assert.same({tag = "Spec", "`if`",
         {tag = "Spec", "a"},
         {tag = "Spec", "`if`",
            {tag = "Spec", "b"},
            {tag = "Spec", "c"},
            {tag = "Spec", "d"}
         },
         {tag = "Spec", "e"}
      }, parse(lex("a ? b ? c : d : e")))
   end)

   it("parses complex expressions", function()
      assert.same({tag = "Spec", "`pipe`",
         {tag = "Spec", "`pipe`",
            {tag = "Spec", "`pipe`",
               {tag = "Spec", "`index`",
                  {tag = "Spec", "`id`"},
                  {tag = "Literal", "books"}
               },
               {tag = "Spec", "filter",
                  {tag = "Spec", "`gte`",
                     {tag = "Spec", "`index`",
                        {tag = "Spec", "`id`"},
                        {tag = "Literal", "year"}
                     },
                     {tag = "Literal", 2000}
                  }
               }
            },
            {tag = "Spec", "`map`",
               {tag = "Spec", "`index`",
                  {tag = "Spec", "`id`"},
                  {tag = "Literal", "ISBN"}
               }
            }
         },
         {tag = "Spec", "sort"}
      }, parse(lex(".books | filter(.year >= 2000) \\ .ISBN | sort")))
   end)
end)
