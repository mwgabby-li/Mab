local module = {}
local literals = require 'literals'
local op = literals.op

local Translator = {
  nextID = 1,
  IDs = {},
  statementNodeNames = {},
  file = "",
}

function Translator:getID(ast)
  if not self.IDs[ast] then
    self.IDs[ast] = self.nextID
    self.nextID = self.nextID + 1
  end
  return self.IDs[ast]
end

function Translator:finalize()
  local rank = ''
  for index, nodeNames in ipairs(self.statementNodeNames) do
    rank = rank .. '{rank=same '
    for _, nodeName in pairs(nodeNames) do
      rank = rank .. ' ' .. nodeName
    end
    rank = rank .. '} '
  end
  
  return 'digraph { \nsplines=false\n' .. self.file .. '\n\n'.. rank .. '\n}\n'
end

function Translator:nodeExpression(ast)
  if ast.tag == 'number' then
    self:appendNode(ast, false, tostring(ast.value))
  elseif ast.tag == 'variable' then
    self:appendNode(ast, false, ast.value)
  elseif ast.tag == 'binaryOp' then
    self:appendNode(ast, false, ast.op, ast.firstChild, nil, ast.secondChild, nil)
    self:nodeExpression(ast.firstChild)
    self:nodeExpression(ast.secondChild)
  elseif ast.tag == 'unaryOp' then
    self:appendNode(ast, false, ast.op, ast.child)
    self:nodeExpression(ast.child)
  else error 'invalid tree'
  end
end

function Translator:nodeName(ast)
  return 'node_' .. self:getID(ast)
end

function Translator:appendNode(ast, sequence, label, firstChild, firstLabel, secondChild, secondLabel, thirdChild, thirdLabel)
  local nodeName = self:nodeName(ast)
  self.file = self.file ..
  nodeName .. " [\n" ..
  'label = "' .. label .. '"'..
  '\n]\n'
  
  local parentPortFirst = ''
  local childPortFirst = ''
  local parentPortSecond = ''
  local childPortSecond = ''
  if sequence then
    parentPortSecond = ':e '
    childPortSecond = ':w '
  elseif not secondChild then
    parentPortFirst = ':s '
    childPortFirst = ':n '
  else
    parentPortFirst = ':sw '
    childPortFirst = ':ne '
    
    parentPortSecond = ':se '
    childPortSecond = ':nw '
  end
  
  if firstChild then
    local label = (firstLabel and ('[ label = "' .. firstLabel  .. '" ];') or ';')
    self.file = self.file .. nodeName .. parentPortFirst .. ' -> ' .. (self:nodeName(firstChild)) .. childPortFirst .. label  .. '\n'
  end

  if secondChild then
    local label = (secondLabel and ('[ label = "' .. secondLabel  .. '" ];') or ';')
    self.file = self.file .. nodeName .. parentPortSecond ..  ' -> ' .. self:nodeName(secondChild) .. childPortSecond .. label .. '\n'
  end
  
  if thirdChild then
    local label = (thirdLabel and ('[ label = "' .. thirdLabel  .. '" ];') or ';')
    self.file = self.file .. nodeName ..  ' -> ' .. self:nodeName(thirdChild) .. label .. '\n'
  end  
end

function Translator:nodeStatement(ast, depth)
  -- Depth is only for nested statements (blocks)
  depth = depth and depth or 1
  -- Create a new table for statements at this depth
  if self.statementNodeNames[depth] == nil then
    self.statementNodeNames[depth] = {}
  end

  if ast.tag == 'emptyStatement' then
    self:appendNode(ast, false, "Empty")
    return
  elseif ast.tag == 'statementSequence' then
    -- Save off statement nodes so that they can be rendered at the same rank on this depth
    self.statementNodeNames[depth][#self.statementNodeNames[depth] + 1] = self:nodeName(ast)
    -- Place the final child of the last statement node at the same rank as well.
    -- Subjectively looks better.
    if ast.secondChild and ast.secondChild.tag ~= 'statementSequence' then
      self.statementNodeNames[depth][#self.statementNodeNames[depth] + 1] = self:nodeName(ast.secondChild)
    end

    self:appendNode(ast, true, 'Statement', ast.firstChild, nil, ast.secondChild, nil)
    self:nodeStatement(ast.firstChild, depth)
    self:nodeStatement(ast.secondChild, depth)
  elseif ast.tag == 'return' then
    self:appendNode(ast, false, 'Return', ast.sentence)    
    self:nodeExpression(ast.sentence)
  elseif ast.tag == 'assignment' then
    self:nodeExpression(ast.assignment)
    -- Identifier is not a table, so make a temporary one representing it.
    -- That way, the AST node will refer to this table,
    -- and we can use this table to create the identifier's node.
    local tempIdentifierTable = {}
    self:appendNode(ast, false, '=', tempIdentifierTable, nil, ast.assignment)
    self:appendNode(tempIdentifierTable, false, ast.identifier)
  elseif ast.tag == 'if' then
    self:appendNode(ast, false, 'If', ast.expression, nil, ast.block, nil, ast.elseBlock, 'Else')
    self:nodeExpression(ast.expression)
    self:nodeStatement(ast.block, depth + 1)
    if ast.elseBlock then
      self:nodeStatement(ast.elseBlock, depth + 1)
    end
  elseif ast.tag == 'print' then
    self:nodeExpression(ast.toPrint)
    self:appendNode(ast, false, 'Print', ast.toPrint)
  else error 'invalid tree'
  end
end

function module.translate(ast)
  Translator.nextID = 1
  Translator.IDs = {}
  Translator.file = ""
  Translator:nodeStatement(ast)
  return Translator:finalize()
end

return module