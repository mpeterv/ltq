local compile = require "ltq.compile"

describe("compile", function()
   it("compiles identity function", function()
      -- \x x
      assert.equal([[
function(v1)
return v1
end]], compile({tag = "Func",
         {tag = "X"}
      }))
   end)

   it("compiles doubling function", function()
      -- \x x + x
      assert.equal([[
function(v1)
return (v1)+(v1)
end]], compile({tag = "Func",
         {tag = "Builtin",
            "add",
            {tag = "X"},
            {tag = "X"}
         }
      }))

      -- \x x * 2
      assert.equal([[
function(v1)
return (v1)*(2)
end]], compile({tag = "Func",
         {tag = "Builtin",
            "multiply",
            {tag = "X"},
            2
         }
      }))
   end)

   it("compiles index function", function()
      -- \x x[1]
      assert.equal([[
function(v1)
return (v1)[1]
end]], compile({tag = "Func",
         {tag = "Builtin",
            "index",
            {tag = "X"},
            1
         }
      }))

      -- \x x[1][x]
      assert.equal([[
function(v1)
return ((v1)[1])[v1]
end]], compile({tag = "Func",
         {tag = "Builtin",
            "index",
            {tag = "Builtin",
               "index",
               {tag = "X"},
               1
            },
            {tag = "X"}
         }
      }))
   end)

   it("compiles map function", function()
      -- \x map(x, \x x + 1)
      assert.equal([[
function(v1)
local v2 = v1
local v3 = {}
for v4 = 1, #v2 do
local v5 = v2[v4]
v3[v4] = (v5)+(1)
end
return v3
end]], compile({tag = "Func",
         {tag = "Builtin",
            "map",
            {tag = "Func",
               {tag = "Builtin",
                  "add",
                  {tag = "X"},
                  1
               }
            },
            {tag = "X"}
         }
      }))

      -- \x map(x.books, \x x.author)
      assert.equal([[
function(v1)
local v2 = (v1)["books"]
local v3 = {}
for v4 = 1, #v2 do
local v5 = v2[v4]
v3[v4] = (v5)["author"]
end
return v3
end]], compile({tag = "Func",
         {tag = "Builtin",
            "map",
            {tag = "Func",
               {tag = "Builtin",
                  "index",
                  {tag = "X"},
                  "author"
               }
            },
            {tag = "Builtin",
               "index",
               {tag = "X"},
               "books"
            }
         }
      }))
   end)

   it("compiles let", function()
      -- \x (\x x * x)(x + x)
      assert.equal([[
function(v1)
local v2 = (v1)+(v1)
return (v2)*(v2)
end]], compile({tag = "Func",
         {tag = "Let",
            {tag = "Builtin",
               "multiply",
               {tag = "X"},
               {tag = "X"}
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
