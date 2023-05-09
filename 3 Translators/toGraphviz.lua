local module = {}
local literals = require 'literals'
local common = require 'common'
local op = literals.op

local Translator = {}

function Translator:new(o)
  o = o or {
    nextID = 1,
    IDs = {},
    statementNodeNames = {},
    ifNodeNames = {},
    file = "",
    errors = {},
  }
  self.__index = self
  setmetatable(o, self)
  return o
end

function Translator:addError(message, ast)
  ast = ast or {}
  self.errors[#self.errors + 1] = {
    message = message,
    position = ast.position,
  }
end

function Translator:getID(ast)
  if not self.IDs[ast] then
    self.IDs[ast] = self.nextID
    self.nextID = self.nextID + 1
  end
  return self.IDs[ast]
end

function Translator:makeRankString(nodes)
  local rank = ''
  for index, nodeNames in ipairs(nodes) do
    if #nodeNames > 0 then
      rank = rank .. '{rank=same'
      for _, nodeName in pairs(nodeNames) do
        rank = rank .. ' ' .. nodeName
      end
      rank = rank .. '} '
    end
  end
  return rank
end

function Translator:finalize()
  local rank = self:makeRankString(self.statementNodeNames) .. self:makeRankString(self.ifNodeNames)
  
  return 'digraph { \nsplines=true\n' .. self.file .. '\n\n'.. rank .. '\n}\n'
end

function Translator:nodeExpression(ast)
  if ast.tag == 'number' then
    self:appendNode(ast, false, tostring(ast.value))
  elseif ast.tag == 'boolean' then
    self:appendNode(ast, false, tostring(ast.value))
  elseif ast.tag == 'variable' then
    self:appendNode(ast, false, ast.value)
  elseif ast.tag == 'functionCall' then
    self:appendNode(ast, false, ast.name .. '()')
  elseif ast.tag == 'newArray' then
    self:appendNode(ast, false, 'new[...]', ast.size, ast.initialValue )
    self:nodeExpression(ast.size)
    self:nodeExpression(ast.initialValue)
  elseif ast.tag == 'arrayElement' then
    self:appendNode(ast, false, '[...]', ast.array, ast.index, nil, '...')
    self:nodeExpression(ast.array)
    self:nodeExpression(ast.index)
  elseif ast.tag == 'binaryOp' then
    self:appendNode(ast, false, ast.op, ast.firstChild, ast.secondChild)
    self:nodeExpression(ast.firstChild)
    self:nodeExpression(ast.secondChild)
  elseif ast.tag == 'unaryOp' then
    self:appendNode(ast, false, ast.op, ast.child)
    self:nodeExpression(ast.child)
  else
    self:addError('Unknown expression node tag "' .. ast.tag .. '."', ast)
  end
end

function Translator:nodeName(ast)
  return 'node_' .. self:getID(ast)
end

function Translator:appendNode(ast, sequence, label, ...)
  local nodeName = self:nodeName(ast)
  self.file = self.file ..
  nodeName .. " [\n" ..
  'label = "' .. label .. '"'..
  '\n]\n'
  
  local arguments = table.pack(...)
  local firstChild = arguments[1]
  local secondChild = arguments[2]

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
    childPortFirst = ':n '
    
    parentPortSecond = ':se '
    childPortSecond = ':n '
  end
  
  local labelsStart = nil
  for i = 1, arguments.n do
    if type(arguments[i]) ~= 'table' then
      labelsStart = i
      break
    end
  end
  
  local firstLabel, secondLabel
  if labelsStart then
    firstLabel = arguments[labelsStart]
    secondLabel = arguments[labelsStart + 1]
  end

  if firstChild then
    local label = (firstLabel and ('[ label = "' .. firstLabel  .. '" ];') or ';')
    self.file = self.file .. nodeName .. parentPortFirst .. ' -> ' .. (self:nodeName(firstChild)) .. childPortFirst .. label  .. '\n'
  end

  if secondChild then
    local label = (secondLabel and ('[ label = "' .. secondLabel  .. '" ];') or ';')
    self.file = self.file .. nodeName .. parentPortSecond ..  ' -> ' .. self:nodeName(secondChild) .. childPortSecond .. label .. '\n'
  end
  
  for i = 3, arguments.n do
    if type(arguments[i]) == 'table' then
      local label = ';'
      if labelsStart then
        local ourLabelIndex = labelsStart + 2 + (i - 3)
        label = (arguments[ourLabelIndex] and ('[ label = "' .. arguments[ourLabelIndex]  .. '" ];') or ';')
      end

      self.file = self.file .. nodeName ..  ' -> ' .. self:nodeName(arguments[i]) .. label .. '\n'
    end
  end
end

function Translator:addNodes(depth)
    -- Create a new table for statements at this depth
  if self.statementNodeNames[depth] == nil then
    self.statementNodeNames[depth] = {}
  end
  
  if self.ifNodeNames[depth] == nil then
    self.ifNodeNames[depth] = {}
  end
end

function Translator:addNodeName(ast, nodeNames, depth)
      -- Save off statement nodes so that they can be rendered at the same rank on this depth
  nodeNames[depth][#nodeNames[depth] + 1] = self:nodeName(ast)
    -- Place the final child of the last statement node at the same rank as well.
    -- Subjectively looks better.
  if ast.secondChild and ast.secondChild.tag ~= ast.tag then
    nodeNames[depth][#nodeNames[depth] + 1] = self:nodeName(ast.secondChild)
  end
  if ast.elseBody and ast.elseBody.tag ~= ast.tag then
    nodeNames[depth][#nodeNames[depth] + 1] = self:nodeName(ast.elseBody)
  end
end

function Translator:nodeStatement(ast, depth, fromIf)
  -- Depth is only for nested statements (blocks)
  depth = depth or 1

  self:addNodes(depth)

  if ast.tag == 'emptyStatement' then
    self:appendNode(ast, false, "Empty")
    return
  elseif ast.tag == 'block' then
    self:appendNode(ast, false, 'Block', ast.body)
    self:nodeStatement(ast.body, depth)
  elseif ast.tag == 'statementSequence' then
    self:addNodeName(ast, self.statementNodeNames, depth)

    self:appendNode(ast, true, 'Statement', ast.firstChild, ast.secondChild)
    self:nodeStatement(ast.firstChild, depth)
    self:nodeStatement(ast.secondChild, depth)
  elseif ast.tag == 'return' then
    self:appendNode(ast, false, 'Return', ast.sentence)
    self:nodeExpression(ast.sentence)
  elseif ast.tag == 'functionCall' then
    self:appendNode(ast, false, ast.name .. '()')
  elseif ast.tag == 'newVariable' then
    if ast.assignment then
      self:appendNode(ast, false, ast.scope .. ' ' .. ast.typeExpression.typeName ..': ' .. ast.value .. ' = ', ast.assignment)
      self:nodeExpression(ast.assignment)    
    else
      self:appendNode(ast, false, ast.scope .. ' ' .. ast.typeExpression.typeName ..': ' .. ast.value)
    end
  elseif ast.tag == 'assignment' then
    self:nodeExpression(ast.assignment)
    self:appendNode(ast, false, '=', ast.writeTarget, ast.assignment)
    self:nodeExpression(ast.writeTarget)
  elseif ast.tag == 'if' then
    self:addNodeName(ast, self.ifNodeNames, depth)
    
    local tag = fromIf and 'Else If' or 'If'
    
    self:appendNode(ast, false, tag, ast.expression, ast.body, ast.elseBody)
    self:nodeExpression(ast.expression)
    self:nodeStatement(ast.body, depth + 1)
    if ast.elseBody then
      self:nodeStatement(ast.elseBody, depth, true)
    end
  elseif ast.tag == 'while' then
    self:appendNode(ast, false, 'While', ast.expression, ast.body)
    self:nodeExpression(ast.expression)
    self:nodeStatement(ast.body, depth + 1)    
  elseif ast.tag == 'print' then
    self:nodeExpression(ast.toPrint)
    self:appendNode(ast, false, 'Print', ast.toPrint)
  else
    self:addError('Unknown statement node tag "' .. ast.tag .. '."', ast)
  end
end

function Translator:nodeFunction(ast)
  local label = 'Function\n' .. '() ➔ ' .. ast.typeExpression.typeName .. ': ' .. ast.name
  if ast.name == literals.entryPointName then
    label = '() ➔ ' .. ast.typeExpression.typeName .. ': Entry Point'
  end

  self:appendNode(ast, false, label, ast.block)
  self:nodeStatement(ast.block)
end

function Translator:translate(ast)
  for i = 1,#ast do
    self:nodeFunction(ast[i])
  end
  return self:finalize(), self.errors
end

function module.translate(ast)
  local translator = Translator:new()
  return translator:translate(ast)
end

return module