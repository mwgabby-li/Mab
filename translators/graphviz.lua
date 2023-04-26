local module = {}
local literals = require 'literals'
local op = literals.op

local Translator = {}

function Translator:new(o)
  o = o or {
    nextID = 1,
    IDs = {},
    statementNodeNames = {},
    ifNodeNames = {},
    file = "",
  }
  self.__index = self
  setmetatable(o, self)
  return o
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
  elseif ast.tag == 'newArray' then
    local copy = {}
    for k, v in ipairs(ast.sizes) do
      copy[k] = v
    end
    copy[#copy + 1] = ast.initialValueExpression
    copy.n = 2 * #ast.sizes + 2
    copy[copy.n] = 'init'
    
    self:appendNode(ast, false, 'new ' .. #ast.sizes .. 'D\narray', table.unpack(copy, 1, copy.n))
    for index, sizeExpression in ipairs(ast.sizes) do
      self:nodeExpression(sizeExpression)
    end
    self:nodeExpression(ast.initialValueExpression)
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
  else error 'invalid tree'
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
  if ast.elseBlock and ast.elseBlock.tag ~= ast.tag then
    nodeNames[depth][#nodeNames[depth] + 1] = self:nodeName(ast.elseBlock)
  end
end

function Translator:nodeStatement(ast, depth, fromIf)
  -- Depth is only for nested statements (blocks)
  depth = depth or 1

  self:addNodes(depth)

  if ast.tag == 'emptyStatement' then
    self:appendNode(ast, false, "Empty")
    return
  elseif ast.tag == 'statementSequence' then
    self:addNodeName(ast, self.statementNodeNames, depth)

    self:appendNode(ast, true, 'Statement', ast.firstChild, ast.secondChild)
    self:nodeStatement(ast.firstChild, depth)
    self:nodeStatement(ast.secondChild, depth)
  elseif ast.tag == 'return' then
    self:appendNode(ast, false, 'Return', ast.sentence)
    self:nodeExpression(ast.sentence)
  elseif ast.tag == 'assignment' then
    self:nodeExpression(ast.assignment)
    self:appendNode(ast, false, '=', ast.writeTarget, ast.assignment)
    self:nodeExpression(ast.writeTarget)
  elseif ast.tag == 'if' then
    self:addNodeName(ast, self.ifNodeNames, depth)
    
    local tag = fromIf and 'Else If' or 'If'
    
    self:appendNode(ast, false, tag, ast.expression, ast.block, ast.elseBlock)
    self:nodeExpression(ast.expression)
    self:nodeStatement(ast.block, depth + 1)
    if ast.elseBlock then
      self:nodeStatement(ast.elseBlock, depth, true)
    end
  elseif ast.tag == 'while' then
    self:appendNode(ast, false, 'While', ast.expression, ast.block)
    self:nodeExpression(ast.expression)
    self:nodeStatement(ast.block, depth + 1)    
  elseif ast.tag == 'print' then
    self:nodeExpression(ast.toPrint)
    self:appendNode(ast, false, 'Print', ast.toPrint)
  else error 'invalid tree'
  end
end

function module.translate(ast)
  local translator = Translator:new()
  translator:nodeStatement(ast)
  return translator:finalize()
end

return module