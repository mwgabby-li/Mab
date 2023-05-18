local module = {}
local literals = require 'literals'
local l_op = literals.op
local common = require 'common'

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
    currentParameters = 0,
    functions = {},
    variables = {},
    numVariables = 0,
    localVariables = {},
    -- Set this to zero so the loop in newVariable will work even in top-level blocks.
    blockBases = {[0] = 0},
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
  local currentParameters = self.currentParameters
  for i=1,#currentParameters do
    if variable == currentParameters[i].name then
        return -(#currentParameters - i)
    end
  end
end

function Translator:codeFunctionCall(ast)
  local function_ = self.functions[ast.name]
  if not function_ then
    self:addError('Undefined function "'..ast.name..'()."', ast)
  else
    local arguments = ast.arguments
    
    if #function_.parameters == #arguments then
      -- Push arguments on the stack for the function
      for i=1,#arguments do
        self:codeExpression(arguments[i])
      end
    elseif function_.defaultArgument and #function_.parameters == #arguments + 1 then
      -- Push arguments on the stack for the function
      for i=1,#arguments do
        self:codeExpression(arguments[i])
      end
      self:codeExpression(function_.defaultArgument)
    else
      local pcount = #function_.parameters
      local acount = #ast.arguments
      self:addError('Function "'..ast.name..'" has '..common.toReadableNumber(pcount, 'parameter')..
                    ' but was sent '..common.toReadableNumber(acount, 'argument')..'.', ast)
      -- Try to do what they asked, I guess...
      for i=1,#arguments do
        self:codeExpression(arguments[i])
      end
    end

    self:addCode('callFunction')
    self:addCode(function_.code)
    -- Function's return code will do the argument popping.
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
    if ast.size.tag ~= 'number' then
      self:addError('New array sizes must be literal numbers.', ast)
    end

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
  elseif ast.tag == 'ternary' then
    -- The test expression
    self:codeExpression(ast.test)
    -- Jump to the false expression if the test fails
    local toFalseExpressionFixup = self:addJump('jumpIfFalse')
    -- The true expression
    self:codeExpression(ast.trueExpression)
    -- If we evaluate the true expression, skip the false one:
    local skipFalseExpressionFixup = self:addJump('jump')
    -- Target to go to the false expression is on the jump to the end
    --  (One past because the PC is incremented before executing the next
    --   instruction after a jump)
    self:fixupJump(toFalseExpressionFixup)
    self:codeExpression(ast.falseExpression)
    -- Target to skip the false expression is the last code in the false expression
    --  (Again, the PC is incremented after a jump.)
    self:fixupJump(skipFalseExpressionFixup)
  else
    self:addError('Unknown expression node tag "' .. ast.tag .. '."', ast)
  end
end

function Translator:codeNewVariable(ast)
  if ast.scope == 'local' then
    local numLocals = #self.localVariables
    for i=numLocals,self.blockBases[#self.blockBases],-1 do
      if self.localVariables[i] == ast.value then
        self:addError('Variable "' .. ast.value .. '" already defined in this scope.', ast)
      end
    end
  elseif self.variables[ast.value] ~= nil then
    self:addError('Re-defining global variable "' .. ast.value .. '."', ast)
  end

  if self.functions[ast.value] then
    self:addError('Creating a variable "'..ast.value..'" with the same name as a function.', ast) 
  end

  -- Both global and local need their expression set up
  if ast.assignment then
    self:codeExpression(ast.assignment)
  -- Default values otherwise!
  else
    if ast.type_ then
      if ast.type_.tag == 'array' then
        self:addError('Default values required for array types. To-Do: Allow this! For now, add a default value to: "' ..
                      ast.value .. '."', ast)
      elseif ast.type_.tag == 'number' then
        self:addCode 'push'
        self:addCode(0)
      elseif ast.type_.tag == 'boolean' then
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
  else
    self:addCode('store')
    self:addCode(self:variableToNumber(ast.value))
  end
end

function Translator:codeAssignment(ast)
  local writeTarget = ast.writeTarget
  if writeTarget.tag == 'variable' then
    self:codeExpression(ast.assignment)
    local index = self:findLocalVariable(ast.writeTarget.value)
    if index then
      self:addCode('storeLocal')
      self:addCode(index)
    elseif self.variables[ast.writeTarget.value] then
      self:addCode('store')
      self:addCode(self:variableToNumber(ast.writeTarget.value))
    else
      self:addError('Assigning to undefined variable "'..ast.writeTarget.value..'."', ast.writeTarget)
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
  -- Save this so we don't write the pop since function returns handle that
  local codingFunction = self.codingFunction
  self.codingFunction = nil

  -- The base of this block is one more than the current number of locals,
  -- since the last local in the table, if any, is from the previous scope.
  local numLocals = #self.localVariables
  self.blockBases[#self.blockBases + 1] = numLocals + 1
  self:codeStatement(ast.body)
  local numToRemove = #self.localVariables - numLocals
  self.blockBases[#self.blockBases] = nil
  -- Remove the trailing numToRemove local variables from the table
  if numToRemove > 0 then
    for i = 1,numToRemove do
      table.remove(self.localVariables)
    end
    
    if not codingFunction then
      self:addCode'pop'
      self:addCode(numToRemove)
    end
  end

  -- Need to save this so that autogenerated function returns will pop the locals.
  self.functionLocalsToRemove = numToRemove
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
    self:addCode(#self.localVariables + #self.currentParameters)
  elseif ast.tag == 'functionCall' then
    self:codeFunctionCall(ast)
    -- Discard return value for function statements, since it's not used by anything.
    self:addCode('pop')
    self:addCode(1)
  elseif ast.tag == 'newVariable' then
    self:codeNewVariable(ast)
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

function Translator:duplicateParameterCheck(ast)
  local parameters = self.functions[ast.name].parameters

  -- Duplicate parameter check
  local duplicates = {}
  local duplicateCount = 0
  for i = 1,#parameters - 1 do
    local parameterName = parameters[i].name
    -- If we haven't counted the duplicates of this parameter yet
    if duplicates[parameterName] == nil then
      for j = i + 1,#parameters do
        if parameterName == parameters[j].name then
          if duplicates[parameterName] then
            duplicates[parameterName].count = duplicates[parameterName].count + 1
          else
            duplicates[parameterName] = { position=parameters[i].position, count=2 }
            duplicateCount = duplicateCount + 1
          end
        end
      end
    end
  end

  if duplicateCount == 1 then
    local name, countAndPosition = next(duplicates)
    local errorMessage = 'Function "'..ast.name..'" has '..common.toReadableNumber(countAndPosition.count)..' instances of the parameter "'..name..'."'
    self:addError(errorMessage, parameters[1])
  elseif duplicateCount > 1 then
    local errorMessage = 'Function "'..ast.name..'" has:\n'
    local num = 0
    for name, countAndPosition in pairs(duplicates) do
      errorMessage = errorMessage..' '..common.toReadableNumber(countAndPosition.count)..' instances of the parameter "'..name
      num = num + 1
      if num + 1 == duplicateCount then
        errorMessage = errorMessage..',"\n and'
      elseif num == duplicateCount then
        errorMessage = errorMessage..'."'
      else
        errorMessage = errorMessage..',"\n'
      end
    end
    self:addError(errorMessage, parameters[1])
  end
end

function Translator:parameterFunctionNameCheck(ast)
  local parameters = self.functions[ast.name].parameters
  for i = 1,#parameters do
    local parameterName = parameters[i].name
    if self.functions[parameterName] then
      self:addError('Parameter "'..parameterName..'" collides with a function of the same name:', parameters[i])
      self:addError('', self.functions[parameterName])
    end
  end
end

function Translator:codeFunction(ast)
  self.currentCode = self.functions[ast.name].code
  self.currentParameters = self.functions[ast.name].parameters

  self:duplicateParameterCheck(ast)
  self:parameterFunctionNameCheck(ast)

  self.codingFunction = true
  self:codeStatement(ast.block)
  if self.currentCode[#self.currentCode - 1] ~= 'return' then
    -- TODO First-class functions/closures... is this correct?
    --      We might have more local variables than this? Or maybe it works differently?
    self:addCode('push')
    -- TODO: Doesn't support creating default returns for arrays.
    if ast.returnType.tag == 'array' then
      self:addError('TODO: Returning default array type not supported, add an explicit return to: "' ..
                    ast.name .. '."', self.functions[ast.name])
    end

    if ast.returnType.tag == 'number' then
      self:addCode(0)
    elseif ast.returnType.tag == 'boolean' then
      self:addCode(false)
    else
      self:addError('Internal error: unknown type "'..ast.returnType.tag ..'" when generating automatic return value.')
      self:addCode(0)
    end
    self:addCode('return')
    self:addCode(self.functionLocalsToRemove + #self.currentParameters)
    self.functionLocalsToRemove = nil
  end
  self.currentCode = nil
end

function Translator:translate(ast)
  local duplicates = {}

  for i = 1,#ast do
    -- No function here? Add one!
    if not self.functions[ast[i].name] then
      self.functions[ast[i].name] = {code = {}, parameters=ast[i].parameters, defaultArgument=ast[i].defaultArgument, position=ast[i].position}
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

  local entryPoint = self.functions[literals.entryPointName]
  if not entryPoint then
    self:addError('No entry point found. (Program must contain a function named "entry point.")')
  else
    entryPoint.code.version = common.toStackVMVersionHash()
    local eppCount = #entryPoint.parameters
    if eppCount > 0 then
      self:addError('Entry point has '..common.toReadableNumber(eppCount, 'parameter')..' but should have none.', entryPoint.parameters[1])
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

  if not entryPoint then
    return nil, self.errors
  else
    return entryPoint.code, self.errors
  end
end

function module.translate(ast)
  local translator = Translator:new()
  return translator:translate(ast)
end

return module