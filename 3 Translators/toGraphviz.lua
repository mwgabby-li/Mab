local module = {}
local common = require 'common'

local kSIMPLIFIED_OUTPUT = false

local Translator = {}

function Translator:new(o)
  o = o or {
    mode = 'vertical',
    --mode = 'horizontal',
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

local function append(table, ...)
  for _, toAppend in ipairs{...} do
    for i, value in ipairs(toAppend) do
      table[#table + 1] = value
    end
  end
  return table
end

local function hasSimpleLabel(ast)
  return ast.tag == 'number' or ast.tag =='boolean' or
         ast.tag == 'string' or ast.tag == 'variable'
end

function Translator:getAsLabel(ast)
  if ast.tag == 'number' or ast.tag =='boolean' then
    return tostring(ast.value)
  elseif ast.tag == 'string' then
    return string.gsub(ast.value, '"', '\\"')
  elseif ast.tag == 'variable' then
    return ast.name
  end
end

function Translator:labelOrArgs(expression, name, fullLabel, args, labels, depth)
  local label = self:getAsLabel(expression)

  if label then
    fullLabel = fullLabel..label
  else
    fullLabel = fullLabel..name
    args[#args+1] = expression
    labels[#labels+1] = name
    self:nodeExpression(expression, depth)
  end
  return fullLabel, label ~= nil
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
  
  return 'digraph { \n splines=true\n '..(self.mode == 'vertical' and 'rankdir=LR' or '')..'\n' .. self.file .. '\n\n'.. rank .. '\n}\n'
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
  elseif ast.tag == 'none' then
    self:appendNode(ast, false, 'none')
  elseif ast.tag == 'string' then
    -- Use only first gsub() return value by surrounding with ()
    self:appendNode(ast, false, (string.gsub(ast.value, '"', '\\"')))
  elseif ast.tag == 'variable' then
    self:appendNode(ast, false, ast.name)
  elseif ast.tag == 'functionCall' then
    self:nodeFunctionCall(ast, depth)
  elseif ast.tag == 'block' then
    self:appendNode(ast, false, '{...}', ast.body)
    self:nodeStatement(ast.body, depth)
  elseif ast.tag == 'newArray' then
    local simpleLabel = true
    local seek = ast
    while seek.tag == 'newArray' do
      if not hasSimpleLabel(seek.size) then
        simpleLabel = false
        break
      end
      seek = seek.initialValue
    end

    if simpleLabel and kSIMPLIFIED_OUTPUT then
      local original = ast
      local args = {}
      local labels = {}
      local fullLabel = 'new'
      while ast.tag == 'newArray' do
        fullLabel = fullLabel..'['
        fullLabel = self:labelOrArgs(ast.size, 'Size', fullLabel, args, labels, depth)
        fullLabel = fullLabel .. ']'
        ast = ast.initialValue
      end
      fullLabel = fullLabel..' '

      fullLabel = self:labelOrArgs(ast, 'Initial', fullLabel, args, labels, depth)

      self:appendNode(original, false, fullLabel, table.unpack(append(args, labels)))
    else
      self:appendNode(ast, false, 'new[...]', ast.size, ast.initialValue )
      self:nodeExpression(ast.size, depth)
      self:nodeExpression(ast.initialValue, depth)
    end
  elseif ast.tag == 'arrayElement' then
    local reversed = {}
    local seek = ast
    while seek.tag == 'arrayElement' do
      reversed[#reversed + 1] = seek
      seek = seek.array
    end

    for i = 1,#reversed // 2 do
      local temp = reversed[i]
      local inverted = #reversed - i + 1
      reversed[i] = reversed[inverted]
      reversed[inverted] = temp
    end

    -- If all of the index elements are simple, just display it as a string.
    local simpleLabel = true
    for _, element in ipairs(reversed) do
      if not hasSimpleLabel(element.index) then
        simpleLabel = false
        break
      end
    end

    if simpleLabel and kSIMPLIFIED_OUTPUT then
      local args = {}
      local labels = {}
      local fullLabel = ''
      fullLabel = self:labelOrArgs(seek, 'Target', fullLabel, args, labels, depth)
      for i, element in ipairs(reversed) do
        fullLabel = fullLabel..'['
        fullLabel = self:labelOrArgs(element.index, ' ['..i..'] ', fullLabel, args, labels, depth)
        fullLabel = fullLabel .. ']'
      end

      self:appendNode(ast, false, fullLabel, table.unpack(append(args, labels)))
    else
      self:appendNode(ast, false, '[...]', ast.array, ast.index, nil, '...')
      self:nodeExpression(ast.array, depth)
      self:nodeExpression(ast.index, depth)
    end
  elseif ast.tag == 'ternary' then
    if kSIMPLIFIED_OUTPUT then
      local ternaryLabel = ''
      local args = {}
      local labels = {}

      local label, added= self:labelOrArgs(ast.test, 'Test', '', args, labels, depth)
      label = label..' ? '
      label = self:labelOrArgs(ast.trueExpression, 'If True', label, args, labels, depth)
      label = label..' : '
      label, addedLabel = self:labelOrArgs(ast.falseExpression, 'If False', label, args, labels, depth)
    else
      self:appendNode(ast, false, '?:', ast.test, ast.trueExpression, ast.falseExpression)
      self:nodeExpression(ast.test, depth)
      self:nodeExpression(ast.trueExpression, depth)
      self:nodeExpression(ast.falseExpression, depth)
    end

    self:appendNode(ast, false, label, table.unpack(append(args, labels)))
  elseif ast.tag == 'binaryOp' then
    if kSIMPLIFIED_OUTPUT and hasSimpleLabel(ast.firstChild) and hasSimpleLabel(ast.secondChild) then
      local args = {}
      local labels = {}
      local label, added = self:labelOrArgs(ast.firstChild, '[1]', '', args, labels, depth)
      label = label..' '..ast.op..' '
      label = self:labelOrArgs(ast.secondChild, '[2]', label, args, labels, depth)
      self:appendNode(ast, false, label, table.unpack(append(args, labels)))
    else
      self:appendNode(ast, false, ast.op, ast.firstChild, ast.secondChild)
      self:nodeExpression(ast.firstChild, depth)
      self:nodeExpression(ast.secondChild, depth)
    end
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
  local thirdChild = type(arguments[3]) == 'table' and arguments[3] or nil

  local parentPortFirst = ''
  local childPortFirst = ''
  local parentPortSecond = ''
  local childPortSecond = ''
  local parentPortThird = ''
  local childPortThird = ''
  if sequence then
    if self.mode == 'vertical' then
      parentPortSecond = ':s '
      childPortSecond = ':n '
    else
      parentPortSecond = ':e '
      childPortSecond = ':w '
    end
  elseif thirdChild then
    if self.mode == 'vertical' then
      parentPortFirst = ':ne '
      childPortFirst = ':w '

      parentPortSecond = ':e '
      childPortSecond = ':w '

      parentPortThird = ':se '
      childPortThird = ':w '
    else
      parentPortFirst = ':sw '
      childPortFirst = ':ne '

      parentPortSecond = ':s '
      childPortSecond = ':n '

      parentPortThird = ':se '
      childPortThird = ':nw '
    end
  elseif secondChild then
    if self.mode == 'vertical' then
      parentPortFirst = ':ne '
      childPortFirst = ':w '

      parentPortSecond = ':se '
      childPortSecond = ':w '
    else
      parentPortFirst = ':sw '
      childPortFirst = ':ne '

      parentPortSecond = ':se '
      childPortSecond = ':nw '
    end
  else
    if self.mode == 'vertical' then
      parentPortFirst = ':e '
      childPortFirst = ':w '
    else
      parentPortFirst = ':s '
      childPortFirst = ':n '
    end
  end
  
  local labelsStart
  for i = 1, arguments.n do
    if arguments[i] and type(arguments[i]) ~= 'table' then
      labelsStart = i
      break
    end
  end
  
  local firstLabel, secondLabel, thirdLabel
  if labelsStart then
    firstLabel = arguments[labelsStart]
    secondLabel = arguments[labelsStart + 1]
    thirdLabel = arguments[labelsStart + 2]
  end

  if firstChild then
    label = (firstLabel and ('[ label = "' .. firstLabel  .. '" ];') or ';')
    self.file = self.file .. nodeName .. parentPortFirst .. ' -> ' .. (self:nodeName(firstChild)) .. childPortFirst .. label  .. '\n'
  end

  if secondChild then
    label = (secondLabel and ('[ label = "' .. secondLabel  .. '" ];') or ';')
    self.file = self.file .. nodeName .. parentPortSecond ..  ' -> ' .. self:nodeName(secondChild) .. childPortSecond .. label .. '\n'
  end
  
  if thirdChild then
    label = (thirdLabel and ('[ label = "' .. thirdLabel  .. '" ];') or ';')
    self.file = self.file .. nodeName .. parentPortThird ..  ' -> ' .. self:nodeName(thirdChild) .. childPortThird .. label .. '\n'
  end

  for i = 4, arguments.n do
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
    -- This makes the AST a bit messy.
    --self:addNodeName(ast, self.ifNodeNames, depth)
    
    local tag = fromIf and 'Else If' or 'If'
    
    self:appendNode(ast, false, tag, ast.expression, ast.body, ast.elseBody, 'condition', '{...}', 'else')
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