local expand = require "ltq.expand"

describe("expand", function()
   it("expands identity function", function()
      -- .
      assert.same({tag = "Func",
         {tag = "X"}
      }, expand({tag = "Spec",
         "`id`"
      }))
   end)

   it("expands literals", function()
      -- 15
      assert.same({tag = "Func",
         15
      }, expand({tag = "Literal",
         15
      }))
   end)

   it("expands nullary macros", function()
      -- #
      assert.same({tag = "Func",
         {tag = "Builtin",
            "len",
            {tag = "X"}
         }
      }, expand({tag = "Spec",
         "`len`"
      }))
   end)

   it("expands binops", function()
      -- . + .
      assert.same({tag = "Func",
         {tag = "Builtin",
            "add",
            {tag = "Call",
               {tag = "Func",
                  {tag = "X"}
               },
               {tag = "X"}
            },
            {tag = "Call",
               {tag = "Func",
                  {tag = "X"}
               },
               {tag = "X"}
            }
         }
      }, expand({tag = "Spec",
         "`add`",
         {tag = "Spec",
            "`id`"
         },
         {tag = "Spec",
            "`id`"
         }
      }))
   end)

   it("expands indexing", function()
      -- .books
      assert.same({tag = "Func",
         {tag = "Builtin",
            "index",
            {tag = "Call",
               {tag = "Func",
                  {tag = "X"}
               },
               {tag = "X"}
            },
            {tag = "Call",
               {tag = "Func",
                  "books"
               },
               {tag = "X"}
            }
         }
      }, expand({tag = "Spec",
         "`index`",
         {tag = "Spec",
            "`id`"
         },
         {tag = "Literal",
            "books"
         }
      }))
   end)

   it("expands nullary named macros", function()
      -- sort
      assert.same({tag = "Func",
         {tag = "Builtin",
            "sort1",
            {tag = "X"}
         }
      }, expand({tag = "Spec",
         "sort0"
      }))
   end)

   it("expands unary named macros", function()
      -- sort(.name)
      assert.same({tag = "Func",
         {tag = "Builtin",
            "sort2",
            {tag = "Func",
               {tag = "Builtin",
                  "index",
                  {tag = "Call",
                     {tag = "Func",
                        {tag = "X"}
                     },
                     {tag = "X"}
                  },
                  {tag = "Call",
                     {tag = "Func",
                        "name"
                     },
                     {tag = "X"}
                  }
               }
            },
            {tag = "X"}
         }
      }, expand({tag = "Spec",
         "sort1",
         {tag = "Spec",
            "`index`",
            {tag = "Spec",
               "`id`"
            },
            {tag = "Literal",
               "name"
            }
         }
      }))
   end)

   it("expands pipe", function()
      -- sort | .[3]
      assert.same({tag = "Func",
         {tag = "Call",
            {tag = "Func",
               {tag = "Builtin",
                  "index",
                  {tag = "Call",
                     {tag = "Func",
                        {tag = "X"}
                     },
                     {tag = "X"}
                  },
                  {tag = "Call",
                     {tag = "Func",
                        3
                     },
                     {tag = "X"}
                  }
               }
            },
            {tag = "Call",
               {tag = "Func",
                  {tag = "Builtin",
                     "sort1",
                     {tag = "X"}
                  }
               },
               {tag = "X"}
            }  
         }
      }, expand({tag = "Spec",
         "`pipe`",
         {tag = "Spec",
            "sort0"
         },
         {tag = "Spec",
            "`index`",
            {tag = "Spec",
               "`id`"
            },
            {tag = "Literal",
               3
            }
         }
      }))
   end)

   it("expands if operator", function()
      -- .flag ? .t : .f
      assert.same({tag = "Func",
         {tag = "Builtin",
            "if",
            {tag = "Call",
               {tag = "Func",
                  {tag = "Builtin",
                     "index",
                     {tag = "Call",
                        {tag = "Func",
                           {tag = "X"}
                        },
                        {tag = "X"}
                     },
                     {tag = "Call",
                        {tag = "Func",
                           "flag"
                        },
                        {tag = "X"}
                     }
                  }
               },
               {tag = "X"}
            },
            {tag = "Call",
               {tag = "Func",
                  {tag = "Builtin",
                     "index",
                     {tag = "Call",
                        {tag = "Func",
                           {tag = "X"}
                        },
                        {tag = "X"}
                     },
                     {tag = "Call",
                        {tag = "Func",
                           "t"
                        },
                        {tag = "X"}
                     }
                  }
               },
               {tag = "X"}
            },
            {tag = "Call",
               {tag = "Func",
                  {tag = "Builtin",
                     "index",
                     {tag = "Call",
                        {tag = "Func",
                           {tag = "X"}
                        },
                        {tag = "X"}
                     },
                     {tag = "Call",
                        {tag = "Func",
                           "f"
                        },
                        {tag = "X"}
                     }
                  }
               },
               {tag = "X"}
            }
         }
      }, expand({tag = "Spec",
         "`if`",
         {tag = "Spec",
            "`index`",
            {tag = "Spec",
               "`id`"
            },
            {tag = "Literal",
               "flag"
            }
         },
         {tag = "Spec",
            "`index`",
            {tag = "Spec",
               "`id`"
            },
            {tag = "Literal",
               "t"
            }
         },
         {tag = "Spec",
            "`index`",
            {tag = "Spec",
               "`id`"
            },
            {tag = "Literal",
               "f"
            }
         }
      }))
   end)
end)
