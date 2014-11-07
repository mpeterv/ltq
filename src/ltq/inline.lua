-- Returns number of times node contains free x, node containing the first one and its index in it.
local function find_free_x(node)
   local count = 0
   local containing_node, index

   for i = 1, #node do
      if type(node[i]) == "table" then
         if node[i].tag == "X" then
            count = count + 1
            containing_node = node
            index = i
         elseif node[i].tag ~= "Func" then
            local sub_count, sub_containing_node, sub_index = find_free_x(node[i])

            count = count + sub_count
            containing_node = containing_node or sub_containing_node
            index = index or sub_index
         end
      end
   end

   return count, containing_node, index
end

-- Replaces (\x A)(B) with A if B == x and with A[x := B] if A contains free x at most once.
local function inline_call(node)
   local func, arg = node[1], node[2]
   assert(func.tag == "Func")
   local body = func[1]

   if arg.tag == "X" then
      -- (\x A)(x) == A
      return body
   elseif body.tag == "X" then
      -- (\x x)(B) == B
      return arg
   else
      local count, containing_node, index = find_free_x(body)

      if count == 0 then
         -- (\x A)(x) == A[x := B] == A
         return body
      elseif count == 1 then
         -- (\x A)(x) == A[x := B]
         containing_node[index] = arg
         return body
      else
         return {tag = "Let", body, arg}
      end
   end
end

-- Inlines calls within node when possible, otherwise replaces calls with let expressions.
local function inline(node)
   for i = 1, #node do
      if type(node[i]) == "table" then
         node[i] = inline(node[i])
      end
   end

   if node.tag == "Call" then
      node = inline_call(node)
   end

   return node
end

return inline
