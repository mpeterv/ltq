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
            "mul",
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

   it("compiles let expression", function()
      -- \x (\x x * x)(x + x)
      assert.equal([[
function(v1)
local v2 = (v1)+(v1)
return (v2)*(v2)
end]], compile({tag = "Func",
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
      }))
   end)

   it("compiles map function", function()
      -- \x map(\x x + 1, x)
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

      -- \x map(\x x.author, x.books)
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

   it("compiles filter function", function()
      -- \x filter(\x x == 1, x)
      assert.equal([[
function(v1)
local v2 = v1
local v3 = {}
local v4 = 0
for v5 = 1, #v2 do
local v6 = v2[v5]
if (v6)==(1) then
v4 = v4 + 1
v3[v4] = v6
end
return v3
end]], compile({tag = "Func",
         {tag = "Builtin",
            "filter",
            {tag = "Func",
               {tag = "Builtin",
                  "eq",
                  {tag = "X"},
                  1
               }
            },
            {tag = "X"}
         }
      }))

      -- \x filter(\x x.author == "J. Doe", x.books)
      assert.equal([[
function(v1)
local v2 = (v1)["books"]
local v3 = {}
local v4 = 0
for v5 = 1, #v2 do
local v6 = v2[v5]
if ((v6)["author"])==("J. Doe") then
v4 = v4 + 1
v3[v4] = v6
end
return v3
end]], compile({tag = "Func",
         {tag = "Builtin",
            "filter",
            {tag = "Func",
               {tag = "Builtin",
                  "eq",
                  {tag = "Builtin",
                     "index",
                     {tag = "X"},
                     "author"
                  },
                  "J. Doe"
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

   it("compiles sort1 function", function()
      -- \x sort1(x.books)
      assert.equal([[
function(v1)
return sort((v1)["books"])
end]], compile({tag = "Func",
         {tag = "Builtin",
            "sort1",
            {tag = "Builtin",
               "index",
               {tag = "X"},
               "books"
            }
         }
      }))
   end)

   it("compiles sort2 function", function()
      -- \x sort2(\x x.year, x.books)
      assert.equal([[
function(v1)
local v2 = (v1)["books"]
local v3 = {}
for v4 = 1, #v2 do
local v5 = v2[v4]
v3[v5] = (v5)["year"]
end
return sort(v2, function(a, b) return v3[a] < v3[b] end)
end]], compile({tag = "Func",
         {tag = "Builtin",
            "sort2",
            {tag = "Func",
               {tag = "Builtin",
                  "index",
                  {tag = "X"},
                  "year"
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
end)
