local inline = require "ltq.inline"

describe("inline", function()
   it("inlines calls with x as argument", function()
      -- (x: x + x)(x) == x + x
      assert.same({tag = "Func",
         {tag = "Thunk",
            "add",
            {tag = "X"},
            {tag = "X"}
         }
      }, inline({tag = "Func",
         {tag = "Call",
            {tag = "Func",
               {tag = "Thunk",
                  "add",
                  {tag = "X"},
                  {tag = "X"}
               }
            },
            {tag = "X"}
         }
      }))
   end)

   it("inlines calls of constant functions", function()
      -- (x: "foo")(x + x) == "foo"
      assert.same({tag = "Func",
         "foo"
      }, inline({tag = "Func",
         {tag = "Call",
            {tag = "Func",
               "foo"
            },
            {tag = "Thunk",
               "add",
               {tag = "X"},
               {tag = "X"}
            }
         }
      }))
   end)

   it("inlines calls of functions using x once", function()
      -- (x: 2*x)(x + x) == 2*(x + x)
      assert.same({tag = "Func",
         {tag = "Thunk",
            "mul",
            2,
            {tag = "Thunk",
               "add",
               {tag = "X"},
               {tag = "X"}
            }
         }
      }, inline({tag = "Func",
         {tag = "Call",
            {tag = "Func",
               {tag = "Thunk",
                  "mul",
                  2,
                  {tag = "X"}
               }
            },
            {tag = "Thunk",
               "add",
               {tag = "X"},
               {tag = "X"}
            }
         }
      }))
   end)

   pending("inlines calls of identity function")
   pending("inlines calls of nested functions")
   pending("does not inline calls of functions when not possible")
end)
