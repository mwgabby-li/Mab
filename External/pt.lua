local function pt (x, order, id, visited)
  visited = visited or {}
  id = id or ""
  order = order or {}
  if type(x) == "string" then return "'" .. tostring(x) .. "'"
  elseif type(x) ~= "table" then return tostring(x)
  elseif visited[x] then return "..."    -- cycle
  else
    visited[x] = true
    local s = id .. "{\n"
    
    -- Copy into a new table
    local newTable = {}
    for k,v in pairs(x) do
      newTable[k] = v
    end
    -- For each ordered key in our list
    for _, v in ipairs(order) do
      -- If the key is in the new table
      if newTable[v] then
        -- Output it
        s = s .. id .. tostring(v) .. " = " .. pt(newTable[v], order, id .. "  ", visited) .. ";\n"
        -- Remove it from the new table
        newTable[v] = nil
      end
    end
    
    -- For the rest of the new table:
    for k,v in pairs(newTable) do
      s = s .. id .. tostring(k) .. " = " .. pt(v, order, id .. "  ", visited) .. ";\n"
    end
    s = s .. id .. "}"
    return s
  end
end

return {pt=pt}
