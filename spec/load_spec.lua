local load = require "ltq.load"

describe("load", function()
   it("loads identity function", function()
      local f = load([[
function(v1)
return v1
end]])
      assert.is_function(f)
      assert.equal(15, f(15))
   end)

   it("loads mapper function", function()
      local f = load([[
function(v1)
local v2 = v1
local v3 = {}
for v4 = 1, #v2 do
local v5 = v2[v4]
v3[v4] = (v5)+(1)
end
return v3
end]])
      assert.is_function(f)
      assert.same({2, 3, 4, 5, 6}, f({1, 2, 3, 4, 5}))
   end)

   it("provides environment as upvalue", function()
      local f = load([[
function(v1)
return sort((v1)["books"])
end]])
      assert.is_function(f)
      assert.same({1, 2, 3, 4, 5}, f({books = {3, 2, 4, 1, 5}}))
   end)
end)
