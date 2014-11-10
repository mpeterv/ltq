local lex = require "ltq.lex"
local parse = require "ltq.parse"
local expand = require "ltq.expand"
local inline = require "ltq.inline"
local compile = require "ltq.compile"
local load = require "ltq.load"

local function pipeline(src)
   local tokens = lex(src)
   local ast = parse(tokens)
   local expanded = expand(ast)
   local inlined = inline(expanded)
   local compiled = compile(inlined)
   local loaded = load(compiled)
   assert.is_function(loaded)
   return loaded, compiled
end

describe("pipeline", function()
   it("builds identity function", function()
      local f, src = pipeline(".")

      assert.equal(26, f(26))
      assert.equal([[
function(v1)
return v1
end]], src)
   end)

   it("builds literals", function()
      local f, src = pipeline("15")

      assert.equal(15, f(26))
      assert.equal([[
function(v1)
return 15
end]], src)
   end)

   it("builds nullary macros", function()
      local f, src = pipeline("#")

      assert.equal(3, f("foo"))
      assert.equal([[
function(v1)
return #(v1)
end]], src)
   end)

   it("builds binops", function()
      local f, src = pipeline(". + .")

      assert.equal(46, f(23))
      assert.equal([[
function(v1)
return (v1)+(v1)
end]], src)
   end)

   it("builds indexing", function()
      local f, src = pipeline(".books")

      assert.equal(41, f({books = 41}))
      assert.equal([[
function(v1)
return (v1)["books"]
end]], src)
   end)

   it("builds nullary named macros", function()
      local f, src = pipeline("sort0")

      assert.same({1, 2, 3, 4, 5}, f({3, 2, 4, 1, 5}))
      assert.equal([[
function(v1)
return sort(v1)
end]], src)
   end)

   it("builds unary named macros", function()
      local f, src = pipeline("sort1(.name)")

      assert.same({
         {name = "Alice"},
         {name = "Bob"},
         {name = "John"}
      }, f({
         {name = "John"},
         {name = "Alice"},
         {name = "Bob"}
      }))
      assert.equal([[
function(v1)
local v2 = v1
local v3 = {}
for v4 = 1, #v2 do
local v5 = v2[v4]
v3[v5] = (v5)["name"]
end
return sort(v2, function(a, b) return v3[a] < v3[b] end)
end]], src)
   end)

   it("builds pipe", function()
      local f, src = pipeline("sort0 | .[3]")

      assert.same(4, f({4, 3, 5, 2, 6}))
      assert.equal([[
function(v1)
return (sort(v1))[3]
end]], src)
   end)

   it("builds if", function()
      local f, src = pipeline(".flag ? .t : .f")

      assert.same(3, f({flag = true, t = 3, f = 5}))
      assert.same(5, f({flag = false, t = 3, f = 5}))
      assert.equal([[
function(v1)
local v2
if (v1)["flag"] then
v2 = (v1)["t"]
else
v2 = (v1)["f"]
end
return v2
end]], src)
   end)

   it("builds a lot of nested macros", function()
      local f, src = pipeline(".books | filter(.year >= 2000) \\ .ISBN | sort0")

      assert.same({
         "1759340132",
         "5839583742",
         "8397623579"
      }, f({books = {
         {
            year = 1997,
            ISBN = "7298240182"
         },
         {
            year = 2000,
            ISBN = "1759340132"
         },
         {
            year = 2014,
            ISBN = "8397623579"
         },
         {
            year = 1993,
            ISBN = "1858283721"
         },
         {
            year = 2001,
            ISBN = "5839583742"
         },
         {
            year = 1999,
            ISBN = "2938566721"
         }
      }}))
      assert.equal([[
function(v1)
local v6 = (v1)["books"]
local v7 = {}
local v8 = 0
for v9 = 1, #v6 do
local v10 = v6[v9]
if ((v10)["year"])>=(2000) then
v8 = v8 + 1
v7[v8] = v10
end
end
local v2 = v7
local v3 = {}
for v4 = 1, #v2 do
local v5 = v2[v4]
v3[v4] = (v5)["ISBN"]
end
return sort(v3)
end]], src)
   end)
end)
