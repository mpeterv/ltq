local inline = require "ltq.inline"

describe("inline", function()
   it("inlines calls with x as argument", function()
      -- (\x x + x)(x) == x + x
      assert.same({tag = "Func",
         {tag = "Builtin",
            "add",
            {tag = "X"},
            {tag = "X"}
         }
      }, inline({tag = "Func",
         {tag = "Call",
            {tag = "Func",
               {tag = "Builtin",
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
      -- (\x "foo")(x + x) == "foo"
      assert.same({tag = "Func",
         "foo"
      }, inline({tag = "Func",
         {tag = "Call",
            {tag = "Func",
               "foo"
            },
            {tag = "Builtin",
               "add",
               {tag = "X"},
               {tag = "X"}
            }
         }
      }))
   end)

   it("inlines calls of functions using x once", function()
      -- (\x 2*x)(x + x) == 2*(x + x)
      assert.same({tag = "Func",
         {tag = "Builtin",
            "mul",
            2,
            {tag = "Builtin",
               "add",
               {tag = "X"},
               {tag = "X"}
            }
         }
      }, inline({tag = "Func",
         {tag = "Call",
            {tag = "Func",
               {tag = "Builtin",
                  "mul",
                  2,
                  {tag = "X"}
               }
            },
            {tag = "Builtin",
               "add",
               {tag = "X"},
               {tag = "X"}
            }
         }
      }))
   end)

   it("inlines calls of nested functions", function()
      -- (\x (\x x * 3)(x + x))(x) == (x + x) * 3
      assert.same({tag = "Func",
         {tag = "Builtin",
            "mul",
            {tag = "Builtin",
               "add",
               {tag = "X"},
               {tag = "X"}
            },
            3
         }
      }, inline({tag = "Func",
         {tag = "Call",
            {tag = "Func",
               {tag = "Call",
                  {tag = "Func",
                     {tag = "Builtin",
                        "mul",
                        {tag = "X"},
                        3
                     }
                  },
                  {tag = "Builtin",
                     "add",
                     {tag = "X"},
                     {tag = "X"}
                  }
               }
            },
            {tag = "X"}
         }
      }))
   end)

   it("replaces calls with let expressions when inlining is not possible", function()
      -- (\x (\x x * x))(x + x)
      assert.same({tag = "Func",
         {tag = "Let",
            {tag = "Builtin",
               "mul",
               {tag = "X"},
               {tag = "X"}
            },
            {tag = "Builtin",
               "add",
               {tag = "X"},
               {tag = "X"}
            }
         }
      }, inline({tag = "Func",
         {tag = "Call",
            {tag = "Func",
               {tag = "Builtin",
                  "mul",
                  {tag = "X"},
                  {tag = "X"}
               },
            },
            {tag = "Builtin",
               "add",
               {tag = "X"},
               {tag = "X"}
            }
         }
      }))
   end)
end)
