local parse_ = require "ltq.parse"

local function parse(src)
   local res, err = parse_(src)
   assert(res, err)
   return res
end

local function perror(src)
   local res, err = parse_(src)
   assert.is_nil(res)
   return err
end

describe("parse", function()
   it("parses identity", function()
      assert.same({tag = "Spec", "`id`"}, parse("."))
   end)

   it("parses literal expressions", function()
      assert.same({tag = "Literal", 1}, parse("1"))
      assert.same({tag = "Literal", false}, parse("(false)"))
   end)

   it("parses nullary macros", function()
      assert.same({tag = "Spec", "`len`"}, parse("#"))
      assert.same({tag = "Spec", "`unm`"}, parse("((-))"))
      assert.same({tag = "Spec", "sort"}, parse("sort"))
      assert.same({tag = "Spec", "sort"}, parse("sort()"))
      assert.same({tag = "Spec", "type"}, parse("(type)"))
   end)

   it("parses unary macros", function()
      assert.same({tag = "Spec", "`len`", {tag = "Literal", "foo"}}, parse("#'foo'"))
      assert.same({tag = "Spec", "`unm`", {tag = "Spec", "`len`"}}, parse("-#"))
      assert.same({tag = "Spec", "sort", {tag = "Spec", "`len`"}}, parse("sort(#)"))
      assert.same({tag = "Spec", "sort", {tag = "Spec", "type"}}, parse("sort(type)"))
   end)

   it("parses multi-parameter macros", function()
      assert.same({tag = "Spec", "foo",
         {tag = "Spec", "bar"},
         {tag = "Literal", 2},
         {tag = "Spec", "baz"}
      }, parse("foo(bar(), 2, baz)"))
   end)

   it("parses indexing macros", function()
      assert.same({tag = "Spec", "`index`",
         {tag = "Spec", "`id`"},
         {tag = "Literal", "foo"}
      }, parse(".foo"))
      assert.same({tag = "Spec", "`index`",
         {tag = "Spec", "`id`"},
         {tag = "Literal", 1}
      }, parse(".[1]"))
      assert.same({tag = "Spec", "`index`",
         {tag = "Spec", "`index`",
            {tag = "Spec", "`id`"},
            {tag = "Literal", "foo"}
         },
         {tag = "Literal", 1}
      }, parse(".foo[1]"))
      assert.same({tag = "Spec", "`index`",
         {tag = "Spec", "`id`"},
         {tag = "Literal", 1},
         {tag = "Literal", "foo"},
         {tag = "Spec", "`index`",
            {tag = "Spec", "`id`"},
            {tag = "Literal", "bar"}
         }
      }, parse(".[1].foo[.bar]"))
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
      }, parse("(.[1][.[2]]).foo"))
   end)

   it("parses table constructing macros", function()
      assert.same({tag = "Spec", "`table`"}, parse("{}"))
      assert.same({tag = "Spec", "`table`",
         {tag = "Literal", 1},
         {tag = "Literal", 1}
      }, parse("{1}"))
      assert.same({tag = "Spec", "`table`",
         {tag = "Literal", 1},
         {tag = "Literal", 1}
      }, parse("{1,}"))
      assert.same({tag = "Spec", "`table`",
         {tag = "Literal", 1},
         {tag = "Spec", "type"},
         {tag = "Literal", 2},
         {tag = "Spec", "`table`"},
         {tag = "Literal", 3},
         {tag = "Literal", 5},
         {tag = "Literal", 4},
         {tag = "Spec", "`len`"}
      }, parse("{type, {}, 5, #}"))
      assert.same({tag = "Spec", "`table`",
         {tag = "Literal", 1},
         {tag = "Spec", "`len`"},
         {tag = "Literal", "type"},
         {tag = "Spec", "type"},
         {tag = "Literal", 2},
         {tag = "Literal", 5}
      }, parse("{#, type = type, 5}"))
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
      }, parse("{[{}] = {}; [.[1]] = .[2];}"))
   end)

   it("parses infix operators", function()
      assert.same({tag = "Spec", "`add`",
         {tag = "Literal", 1},
         {tag = "Literal", 2}
      }, parse("1 + 2"))
      assert.same({tag = "Spec", "`add`",
         {tag = "Spec", "`unm`",
            {tag = "Literal", 1}
         },
         {tag = "Literal", 2}
      }, parse("- 1 + 2"))
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
      }, parse(".foo + .bar * 4"))
      assert.same({tag = "Spec", "`pow`",
         {tag = "Spec", "a"},
         {tag = "Spec", "`pow`",
            {tag = "Spec", "b"},
            {tag = "Spec", "c"}
         }
      }, parse("a^b^c"))
      assert.same({tag = "Spec", "`concat`",
         {tag = "Spec", "a"},
         {tag = "Spec", "`concat`",
            {tag = "Spec", "b"},
            {tag = "Spec", "c"}
         }
      }, parse("a..b..c"))
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
      }, parse("a == b and c == d or e ~= f"))
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
      }, parse("type == 'table' ? .value : ."))
      assert.same({tag = "Spec", "`if`",
         {tag = "Spec", "a"},
         {tag = "Spec", "b"},
         {tag = "Spec", "`if`",
            {tag = "Spec", "c"},
            {tag = "Spec", "d"},
            {tag = "Spec", "e"}
         }
      }, parse("a ? b : c ? d : e"))
      assert.same({tag = "Spec", "`if`",
         {tag = "Spec", "a"},
         {tag = "Spec", "`if`",
            {tag = "Spec", "b"},
            {tag = "Spec", "c"},
            {tag = "Spec", "d"}
         },
         {tag = "Spec", "e"}
      }, parse("a ? b ? c : d : e"))
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
      }, parse(".books | filter(.year >= 2000) \\ .ISBN | sort"))
   end)

   it("returns error on invalid input", function()
      assert.equal("ltq:1:1: expected expression near EOF", perror(""))
      assert.equal([[
ltq:1:5: expected expression
    # + 
        ^]], perror([[# + ]]))
      assert.equal([[
ltq:1:7: <eof> expected
    a + b c
          ^]], perror([[a + b c]]))
      assert.equal([[
ltq:1:6: ')' expected
    foo(a}
         ^]], perror([[foo(a}]]))
      assert.equal([[
ltq:1:7: '=' expected
    {[foo]}
          ^]], perror([[{[foo]}]]))
      assert.equal("ltq:3:1: '}' expected (to close '{' at line 1) near EOF", perror([[
{
   [foo] = bar
]]))
      assert.equal([[
ltq:3:1: ')' expected (to close '(' at line 1)
    }
    ^]], perror([[
foo(
   c - d
}
]]))
   end)
end)
