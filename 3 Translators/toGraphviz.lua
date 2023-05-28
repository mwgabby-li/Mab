local module = {}
local common = require 'common'

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

function Translator:addError(...)
  if self.errorReporter then
    self.errorReporter:addError(...)
  end
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
  for _, nodeNames in ipairs(nodes) do
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
  
  return 'digraph { \n splines=true\n' .. self.file .. '\n\n'.. rank .. '\n}\n'
end

function Translator:nodeFunctionCall(ast, depth)  
  local target = ast.target
  while target.tag == 'arrayElement' do
    target = target.array
  end

  local argumentList = 'none'
  if #ast.arguments > 0 then
    argumentList = '(...)'
  end
  
  self:appendNode(ast, false, target.name .. argumentList, table.unpack(ast.arguments))
  for _, argument in ipairs(ast.arguments) do
    self:nodeExpression(argument, depth + 1)
  end
end

function Translator:nodeExpression(ast, depth)
  if ast.tag == 'number' or ast.tag =='boolean' then
    self:appendNode(ast, false, tostring(ast.value))
  elseif ast.tag == 'string' then
    self:appendNode(ast, false, string.gsub(ast.value, '"', '\\"'))
  elseif ast.tag == 'variable' then
    self:appendNode(ast, false, ast.name)
  elseif ast.tag == 'functionCall' then
    self:nodeFunctionCall(ast, depth)
  elseif ast.tag == 'block' then
    self:appendNode(ast, false, '{...}', ast.body)
    self:nodeStatement(ast.body, depth)
  elseif ast.tag == 'newArray' then
    self:appendNode(ast, false, 'new[...]', ast.size, ast.initialValue )
    self:nodeExpression(ast.size, depth)
    self:nodeExpression(ast.initialValue, depth)
  elseif ast.tag == 'arrayElement' then
    self:appendNode(ast, false, '[...]', ast.array, ast.index, nil, '...')
    self:nodeExpression(ast.array, depth)
    self:nodeExpression(ast.index, depth)
  elseif ast.tag == 'ternary' then
    self:appendNode(ast, false, '?:', ast.test, ast.trueExpression, ast.falseExpression)
    self:nodeExpression(ast.test, depth)
    self:nodeExpression(ast.trueExpression, depth)
    self:nodeExpression(ast.falseExpression, depth)
  elseif ast.tag == 'binaryOp' then
    self:appendNode(ast, false, ast.op, ast.firstChild, ast.secondChild)
    self:nodeExpression(ast.firstChild, depth)
    self:nodeExpression(ast.secondChild, depth)
  elseif ast.tag == 'unaryOp' then
    self:appendNode(ast, false, ast.op, ast.child)
    self:nodeExpression(ast.child, depth)
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
  local secondChild = type(arguments[2]) == 'table' and arguments[2] or nil

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
  
  local labelsStart
  for i = 1, arguments.n do
    if arguments[i] and type(arguments[i]) ~= 'table' then
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
    label = (firstLabel and ('[ label = "' .. firstLabel  .. '" ];') or ';')
    self.file = self.file .. nodeName .. parentPortFirst .. ' -> ' .. (self:nodeName(firstChild)) .. childPortFirst .. label  .. '\n'
  end

  if secondChild then
    label = (secondLabel and ('[ label = "' .. secondLabel  .. '" ];') or ';')
    self.file = self.file .. nodeName .. parentPortSecond ..  ' -> ' .. self:nodeName(secondChild) .. childPortSecond .. label .. '\n'
  end
  
  for i = 3, arguments.n do
    if type(arguments[i]) == 'table' then
      label = ';'
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
    self:appendNode(ast, false, '{...}', ast.body)
    self:nodeStatement(ast.body, depth + 1)
  elseif ast.tag == 'statementSequence' then
    self:addNodeName(ast, self.statementNodeNames, depth)
    self:appendNode(ast, true, 'Statement', ast.firstChild, ast.secondChild)
    self:nodeStatement(ast.firstChild, depth)
    self:nodeStatement(ast.secondChild, depth)
  elseif ast.tag == 'return' then
    self:appendNode(ast, false, 'Return', ast.sentence)
    self:nodeExpression(ast.sentence, depth)
  elseif ast.tag == 'functionCall' then
    self:nodeFunctionCall(ast, depth)
  elseif ast.tag == 'newVariable' then
    local scopeLabel = ast.scope..' '
    if (depth == 1 and scopeLabel == 'global ') or (depth > 1 and scopeLabel == 'local ') then
      scopeLabel = ' '
    end
    if ast.assignment then
      if ast.assignment.tag == 'block' then
        depth = depth + 1;
        self:appendNode(ast, false, ast.name .. ':'..scopeLabel..'\n'..common.toReadableType(ast.type_), ast.assignment.body, '{...}')
        self:nodeStatement(ast.assignment.body, depth)
      else
        self:appendNode(ast, false, ast.name .. ':'..scopeLabel..'\n'..common.toReadableType(ast.type_), ast.assignment)
        self:nodeExpression(ast.assignment, depth)
      end
    else
      self:appendNode(ast, false, ast.name..':'..scopeLabel..'\n'..common.toReadableType(ast.type_))
    end
  elseif ast.tag == 'assignment' then
    self:nodeExpression(ast.assignment, depth)
    self:appendNode(ast, false, '<-', ast.target, ast.assignment)
    self:nodeExpression(ast.target, depth)
  elseif ast.tag == 'if' then
    self:addNodeName(ast, self.ifNodeNames, depth)
    
    local tag = fromIf and 'Else If' or 'If'
    
    self:appendNode(ast, false, tag, ast.expression, ast.body, ast.elseBody)
    depth = depth + 1
    self:nodeExpression(ast.expression, depth)
    self:nodeStatement(ast.body, depth)
    if ast.elseBody then
      self:nodeStatement(ast.elseBody, depth, true)
    end
  elseif ast.tag == 'while' then
    self:appendNode(ast, false, 'While', ast.expression, ast.body)
    depth = depth + 1
    self:nodeExpression(ast.expression, depth)
    self:nodeStatement(ast.body, depth)
  elseif ast.tag == 'print' then
    depth = depth + 1
    self:nodeExpression(ast.toPrint, depth)
    self:appendNode(ast, false, 'Print', ast.toPrint)
  else
    self:addError('Unknown statement node tag "' .. ast.tag .. '."', ast)
  end
end

function Translator:translate(ast)
  for i = 1,#ast do
    self:nodeStatement(ast[i])
  end
  return self:finalize()
end

function module.translate(ast, parameters)
  local translator = Translator:new()
  translator.errorReporter = common.ErrorReporter:new()
  if parameters then
    translator.errorReporter.stopAtFirstError = parameters.stopAtFirstError
  end
  return translator.errorReporter,
         translator.errorReporter:pcallAddErrorOnFailure(translator.translate, translator, ast)
end

return module