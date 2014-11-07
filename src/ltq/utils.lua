local utils = {}

utils.unpack = table.unpack or unpack

if _VERSION:find("5.1") then
   utils.loadstring = loadstring
else
   utils.loadstring = load
end

local function flatten_into(array, res)
   for i = 1, #array do
      if type(array[i]) == "table" then
         flatten_into(array[i], res)
      else
         res[#res + 1] = array[i]
      end
   end

   return res
end

function utils.flatten(array)
   return flatten_into(array, {})
end

return utils
