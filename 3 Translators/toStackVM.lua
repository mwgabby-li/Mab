local module = {}
local literals = require 'literals'
local l_op = literals.op
local common = require 'common'

local ExpectedASTVersion = require('expectedversions').AST.StackVM

local Translator = {}

local toName = {
  [l_op.add] = 'add',
  [l_op.subtract] = 'subtract',
  [l_op.multiply] = 'multiply',
  [l_op.divide] = 'divide',
  [l_op.modulus] = 'modulus',
  [l_op.exponent] = 'exponent',
  [l_op.less] = 'less',
  [l_op.greater] = 'greater',
  [l_op.lessOrEqual] = 'lessOrEqual',
  [l_op.greaterOrEqual] = 'greaterOrEqual',
  [l_op.equal] = 'equal',
  [l_op.notEqual] = 'notEqual',
  [l_op.not_] = 'not',
  [l_op.and_] = 'and',
  [l_op.or_] = 'or',
}

local unaryToName = {
  [l_op.negate] = 'negate',
  [l_op.not_] = 'not',
}

function Translator:new(o)
  o = o or {
    errors = {},
    currentCode = {},
    functions = {},
    variables = {},
    numVariables = 0,
    localVariables = {},
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

function Translator:currentInstructionIndex()
  return #self.currentCode
end

function Translator:addJump(opcode, target)
  self:addCode(opcode)
  -- No target? Add placeholder.
  if target == nil then
    self:addCode(0)
    -- Will return the location of the 'zero' placeholder we just inserted.
    return self:currentInstructionIndex()
  else
    -- Jump start address is the location of the jump opcode,
    -- which is the current instruction after we add it.
    local jumpCodeToTarget = target - self:currentInstructionIndex()
    -- We need to end up at the instruction /before/ the target,
    -- because PC is incremented by one after jumps.
    self:addCode(jumpCodeToTarget - 1)
  end
end

function Translator:fixupJump(location)
  self.currentCode[location] = self:currentInstructionIndex() - location
end

function Translator:addCode(opcode)
  self.currentCode[#self.currentCode + 1] = opcode
end

function Translator:variableToNumber(variable)
  local number = self.variables[variable]
  if not number then
    number = self.numVariables + 1
    self.numVariables = number
    self.variables[variable] = number
  end
  return number
end

function Translator:findLocalVariable(variable)
  local localVariables = self.localVariables
  for i=#localVariables,1,-1 do
    if variable == localVariables[i] then
      return i
    end
  end
end

function Translator:codeFunctionCall(ast)
  local function_ = self.functions[ast.name]
  if not function_ then
    self:addError('Undefined function "'..ast.name..'()."', ast)
  else
    self:addCode('callFunction')
    self:addCode(function_.code)
  end
end

function Translator:codeExpression(ast)
  if ast.tag == 'number' or ast.tag == 'boolean' then
    self:addCode('push')
    self:addCode(ast.value)
  elseif ast.tag == 'variable' then
    local index = self:findLocalVariable(ast.value)
    if index then
      self:addCode'loadLocal'
      self:addCode(index)
    elseif self.variables[ast.value] then
      self:addCode('load')
      self:addCode(self:variableToNumber(ast.value))
    else
      self:addError('Trying to load from undefined variable "' .. ast.value .. '."', ast) 
    end
  elseif ast.tag == 'functionCall' then
    self:codeFunctionCall(ast)
  elseif ast.tag == 'arrayElement' then
    self:codeExpression(ast.array)
    self:codeExpression(ast.index)
    self:addCode('getArray')
  elseif ast.tag == 'newArray' then
    self:codeExpression(ast.initialValue)
    self:codeExpression(ast.size)
    self:addCode('newArray')
  elseif ast.tag == 'binaryOp' then
    if ast.op == l_op.and_ then
      self:codeExpression(ast.firstChild)
      local fixupSSAnd = self:addJump('jumpIfFalseJumpNoPop')
      self:codeExpression(ast.secondChild)
      self:fixupJump(fixupSSAnd)
    elseif ast.op == l_op.or_ then
      self:codeExpression(ast.firstChild)
      local fixupSSOr = self:addJump('jumpIfTrueJumpNoPop')
      self:codeExpression(ast.secondChild)
      self:fixupJump(fixupSSOr)
    else    
      self:codeExpression(ast.firstChild)
      self:codeExpression(ast.secondChild)
      self:addCode(toName[ast.op])
    end
  elseif ast.tag == 'unaryOp' then
    self:codeExpression(ast.child)
    if ast.op ~= '+' then
      self:addCode(unaryToName[ast.op])
    end
  else
    self:addError('Unknown expression node tag "' .. ast.tag .. '."', ast)
  end
end

function Translator:codeAssignment(ast)
  local writeTarget = ast.writeTarget
  if writeTarget.tag == 'variable' then
    if self.functions[ast.writeTarget.value] then
      self:addError('Assigning to variable "'..ast.writeTarget.value..'" with the same name as a function.', ast.writeTarget) 
    end
    
    self:codeExpression(ast.assignment)
    local index = self:findLocalVariable(ast.writeTarget.value)
    if index then
      self:addCode('storeLocal')
      self:addCode(index)
    else
      self:addCode('store')
      self:addCode(self:variableToNumber(ast.writeTarget.value))
    end
  elseif writeTarget.tag == 'arrayElement' then
    self:codeExpression(ast.writeTarget.array)
    self:codeExpression(ast.writeTarget.index)
    self:codeExpression(ast.assignment)
    self:addCode('setArray')
  else
    self:addError('Unknown write target type, tag was "'..tostring(ast.tag)..'."', ast)
  end
end

function Translator:codeBlock(ast)
  if self.codingFunction then
    self.codingFunction = nil
    self:codeStatement(ast.body)
  else
    local localsBeforeBlock = #self.localVariables
    self:codeStatement(ast.body)
    local numToRemove = #self.localVariables - localsBeforeBlock
    if numToRemove > 0 then
      for i = 1,numToRemove do
        table.remove(self.localVariables)
      end
      self:addCode'pop'
      self:addCode(numToRemove)
    end
  end
end

function Translator:codeStatement(ast)
  if ast.tag == 'emptyStatement' then
    return
  elseif ast.tag == 'block' then
    self:codeBlock(ast)
  elseif ast.tag == 'statementSequence' then
    self:codeStatement(ast.firstChild)
    self:codeStatement(ast.secondChild)
  elseif ast.tag == 'return' then
    self:codeExpression(ast.sentence)
    self:addCode('return')
    -- Add the number of locals at this time so we can update the stack.
    self:addCode(#self.localVariables)
  elseif ast.tag == 'functionCall' then
    self:codeFunctionCall(ast)
    -- Discard return value for function statements, since it's not used by anything.
    self:addCode('pop')
    self:addCode(1)
  elseif ast.tag == 'newVariable' then
    -- Both global and local need their expression set up
    if ast.assignment then
      self:codeExpression(ast.assignment)
    -- Default values otherwise!
    else
      if ast.typeExpression then
        if ast.typeExpression.typeName == 'number' then
          self:addCode 'push'
          self:addCode(0)
        elseif ast.typeExpression.typeName == 'boolean' then
          self:addCode 'push'
          self:addCode(false)
        else
          self:addError('No type for variable "' .. ast.value .. '."', ast)
          self:addCode 'push'
          self:addCode(0)
        end
      end
    end
    
    if ast.scope == 'local' then
      self.localVariables[#self.localVariables + 1] = ast.value
    -- TODO: Needs to check for errors: name collisions. Any others?
    else
      self:addCode('store')
      self:addCode(self:variableToNumber(ast.value))
    end
  elseif ast.tag == 'assignment' then
    self:codeAssignment(ast)
  elseif ast.tag == 'if' then
    -- Expression and jump
    self:codeExpression(ast.expression)
    local skipIfFixup = self:addJump('jumpIfFalse')
    -- Inside of if
    self:codeStatement(ast.body)
    if ast.elseBody then
      -- If else, we need an instruction at the end of
      -- the 'if' body to jump past the 'else' body
      local skipElseFixup = self:addJump('jump')

      -- And our target for failing the 'if' is this 'else,'
      -- so set its target here after the jump to the end of 'else.'
      self:fixupJump(skipIfFixup)
      -- Fill out the 'else'
      self:codeStatement(ast.elseBody)

      -- Finally, set the 'skip else' jump to here, after the 'else' body
      self:fixupJump(skipElseFixup)
    else
      self:fixupJump(skipIfFixup)
    end
  elseif ast.tag == 'while' then
    local whileStart = self:currentInstructionIndex()
    self:codeExpression(ast.expression)
    local skipWhileFixup = self:addJump 'jumpIfFalse'
    self:codeStatement(ast.body)
    self:addJump('jump', whileStart)
    self:fixupJump(skipWhileFixup)
  elseif ast.tag == 'print' then
    self:codeExpression(ast.toPrint)
    self:addCode('print')
  else
    self:addError('Unknown statement node tag "' .. ast.tag .. '."', ast)
  end
end

function Translator:codeFunction(ast)
  self.currentCode = self.functions[ast.name].code
  self.codingFunction = true
  self:codeStatement(ast.block)
  if self.currentCode[#self.currentCode] ~= 'return' then
    self:addCode('push')
    self:addCode(0)
    self:addCode('return')
    self:addCode(0)
  end
  self.currentCode = nil
end

function Translator:translate(ast)
  if not common.verifyVersionAndReportError(self, 'stack VM translation', ast, 'AST', ExpectedASTVersion) then
    return nil, self.errors
  end

  local duplicates = {}

  for i = 1,#ast do
    -- No function here? Add one!
    if not self.functions[ast[i].name] then
      self.functions[ast[i].name] = {code = {}, position=ast[i].position}
    -- Otherwise, duplication detected!
    else
      -- First duplicate: Set name, and position of first definition
      if duplicates[ast[i].name] == nil then
        duplicates[ast[i].name] = {}
        duplicates[ast[i].name][#duplicates[ast[i].name] + 1] = self.functions[ast[i].name].position
      end
      
      -- First and subsequent duplicates, add position of this duplicate
      duplicates[ast[i].name][#duplicates[ast[i].name] + 1] = ast[i].position
    end
  end

  -- Report error. Since we list the number of duplicates, we do this as a second pass.
  for name, duplicate_positions in pairs(duplicates) do
    if #duplicate_positions > 0 then
      self:addError(#duplicate_positions .. ' duplicate functions sharing name "'..name..'."')
      for index,position in ipairs(duplicate_positions) do
        self:addError(index .. ': ', {position=position})
      end
    end
  end

  for i = 1,#ast do
    self:codeFunction(ast[i])
  end
  
  local entryPoint = self.functions[literals.entryPointName]
  if not entryPoint then
    self:addError('No entry point found. (Program must contain a function named "entry point.")')
    return nil, self.errors
  else
    entryPoint.code.version = common.toStackVMVersionHash()
    return entryPoint.code, self.errors
  end
end

function module.translate(ast)
  local translator = Translator:new()
  return translator:translate(ast)
end

return module