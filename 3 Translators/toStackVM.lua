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
    currentCode = {},
    currentParameters = {},
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

function Translator:addError(...)
  if self.errorReporter then
    self.errorReporter:addError(...)
  end
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
  local existingVariable = self.variables[variable.name]
  if not existingVariable then
    number = self.numVariables + 1
    self.numVariables = number
    local newVariable = { number = number, type_ = variable.type_ }
    self.variables[variable.name] = newVariable
    return number, newVariable
  end
  return existingVariable.number, existingVariable
end

function Translator:findLocalVariable(variable)
  local localVariables = self.localVariables
  for i=#localVariables,1,-1 do
    if variable == localVariables[i].name then
      return i, localVariables[i]
    end
  end
  local currentParameters = self.currentParameters
  for i=1,#currentParameters do
    if variable == currentParameters[i].name then
        return -(#currentParameters - i), currentParameters[i]
    end
  end
end

function Translator:codeFunctionCall(ast)
  local indexOrNumber, functionCodeReference = self:findLocalVariable(ast.name)
  local isGlobal = false
  if not functionCodeReference then
    indexOrNumber, functionCodeReference = self:variableToNumber(ast)
    isGlobal = true
  end
  
  if not functionCodeReference then
    self:addError('Cannot call function, "'..ast.name..'" is undefined.', ast)
  else
    local arguments = ast.arguments
    local functionType = functionCodeReference.type_
    local parameters = functionType.parameters
    
    if #parameters == #arguments then
      -- Push arguments on the stack for the function
      for i=1,#arguments do
        self:codeExpression(arguments[i])
      end
    elseif functionType.defaultArgument and #parameters == #arguments + 1 then
      -- Push arguments on the stack for the function
      for i=1,#arguments do
        self:codeExpression(arguments[i])
      end
      self:codeExpression(functionType.defaultArgument)
    else
      local pcount = #functionType.parameters
      local acount = #ast.arguments
      self:addError('Function "'..ast.name..'" has '..common.toReadableNumber(pcount, 'parameter')..
                    ' but was sent '..common.toReadableNumber(acount, 'argument')..'.', ast)
      -- Try to do what they asked, I guess...
      for i=1,#arguments do
        self:codeExpression(arguments[i])
      end
    end

    if not isGlobal then
      self:codeLoadVariable(ast, indexOrNumber)
    else
      self:codeLoadVariable(ast, nil, indexOrNumber)
    end

    self:addCode('callFunction')
    -- Code is from the stack.
    -- Function's return code will do the argument popping.
  end
end

function Translator:codeLoadVariable(ast, localIndex, globalNumber)
    local index = localIndex or self:findLocalVariable(ast.name)
    if index then
      self:addCode'loadLocal'
      self:addCode(index)
    elseif globalNumber or self.variables[ast.name] then
      self:addCode('load')
      self:addCode(self:variableToNumber(ast))
    else
      self:addError('Trying to load from undefined variable "' .. ast.name .. '."', ast)
    end

end

function Translator:codeExpression(ast)
  if ast.tag == 'number' or ast.tag == 'boolean' then
    self:addCode('push')
    self:addCode(ast.value)
  elseif ast.tag == 'variable' then
    self:codeLoadVariable(ast)
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

function Translator:checkForVariableNameCollisions(ast)
  local inferredScope = self:inferScope(ast)

  -- This is the check for duplicate locals and globals in the same scope
  if inferredScope == 'local' then
    local numLocals = #self.localVariables
    for i=numLocals,self.blockBases[#self.blockBases],-1 do
      if i > 0 and self.localVariables[i].name == ast.name then
        self:addError('Variable "' .. ast.name .. '" already defined in this scope.', ast)
      end
    end
  elseif inferredScope == 'global' then
    if self.variables[ast.name] ~= nil then
      self:addError('Re-defining global variable "' .. ast.name .. '."', ast)
    end
  else
    if result ~= nil then
      self:addError('Unknown scope .."'..tostring(result)..'."', ast)
    else
      self:addError('Scope undefined.', ast)
    end
  end
end

function Translator:inferScope(ast)
  local result = ast.scope

  -- Top-level scopes default to 'global' if unspecified
  if result == 'unspecified' then
    if #self.blockBases == 0 then
      result = 'global'
    else
      result = 'local'
    end
  elseif result ~= 'local' and result ~= 'global' then
    if result ~= nil then
      self:addError('Unknown scope .."'..tostring(result)..'."', ast)
    else
      self:addError('Scope undefined.', ast)
    end
    result = 'local'
  end

  return result
end

function Translator:codeNewVariable(ast)
  if #self.blockBases > 0 then
    self:checkForVariableNameCollisions(ast)
  end

  -- Both global and local need their expression set up
  if ast.assignment then
    if ast.assignment.tag ~= 'block' then
      self:codeExpression(ast.assignment)
    else
      local code = self:codeFunction(ast, ast.type_, ast.assignment)
      -- Put the code on the stack to be loaded into this variable.
      self:addCode 'push'
      self:addCode(code)
    end
  -- Default values otherwise!
  else
    if ast.type_ then
      if ast.type_.tag == 'array' then
        self:addError('Default values required for array types. To-Do: Allow this! For now, add a default value to: "' ..
                      ast.name .. '."', ast)
      elseif ast.type_.tag == 'number' then
        self:addCode 'push'
        self:addCode(0)
      elseif ast.type_.tag == 'boolean' then
        self:addCode 'push'
        self:addCode(false)
      elseif ast.type_.tag == 'function' then
        -- TODO: A default value for a function? Maybe code that returns the default return type?
        self:addCode 'push'
        self:addCode(0)
      else
        self:addError('No type for variable "' .. ast.name .. '."', ast)
        self:addCode 'push'
        self:addCode(0)
      end
    end
  end

  -- If we aren't already tracking this variable and it's local,
  -- start tracking its position.
  local scope = self:inferScope(ast)
  if scope == 'local' then
    -- Track it and its position.
    self.localVariables[#self.localVariables + 1] =  {name = ast.name, type_ = ast.type_}
  -- Otherwise, load whatever's in the stack into this variable.
  elseif scope == 'global' then
    self:addCode('store')
    self:addCode(self:variableToNumber(ast))
  else
    if scope ~= nil then
      self:addError('Unknown scope .."'..tostring(result)..'."', ast)
    else
      self:addError('Scope undefined.', ast)
    end
  end
end

function Translator:codeAssignment(ast)
  local writeTarget = ast.writeTarget
  if writeTarget.tag == 'variable' then
    self:codeExpression(ast.assignment)
    local index = self:findLocalVariable(ast.writeTarget.name)
    if index then
      self:addCode('storeLocal')
      self:addCode(index)
    elseif self.variables[ast.writeTarget.name] then
      self:addCode('store')
      self:addCode(self:variableToNumber(ast.writeTarget))
    else
      self:addError('Assigning to undefined variable "'..ast.writeTarget.name..'."', ast.writeTarget)
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

function Translator:duplicateParameterCheck(type_)
  local parameters = type_.parameters

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

function Translator:codeFunction(name, type_, block)
  local previousCode = self.currentCode
  self.currentCode = {}
  self.currentParameters = type_.parameters

  self:duplicateParameterCheck(type_)

  self.codingFunction = true
  self:codeStatement(block)
  if self.currentCode[#self.currentCode - 1] ~= 'return' then
    self:addCode('push')
    -- TODO: Doesn't support creating default returns for arrays.
    local resultTypeTag = type_.resultType.tag
    if resultTypeTag == 'array' then
      self:addError('TODO: Returning default array type not supported, add an explicit return to: "' ..
                    name or 'anonymous function' .. '."', block)
    end

    if resultTypeTag == 'number' then
      self:addCode(0)
    elseif resultTypeTag == 'boolean' then
      self:addCode(false)
    -- TODO: Rename 'unknown' to 'unspecified.'
    elseif resultTypeTag == 'unknown' then
      -- This is valid. Note that a function like this, with no return type,
      -- is only allowed to be executed as a statement.
      -- Any other use will cause a type checker error.
      self:addCode(false)
    else
      self:addError('Internal error: unknown type "'..resultTypeTag..'" when generating automatic return value.')
      self:addCode(0)
    end
    self:addCode('return')
    self:addCode(self.functionLocalsToRemove + #self.currentParameters)
    self.functionLocalsToRemove = nil
  end

  -- TODO: More elegant way of doing this?
  local generatedCode = self.currentCode
  self.currentCode = previousCode
  return generatedCode
end

function Translator:translate(ast)
  local duplicates = {}
  
  local firstPositions = {}

  for i = 1,#ast do
    if not self.variables[ast[i].name] then
      self:variableToNumber(ast[i])
      firstPositions[ast[i].name] = ast[i].position
    -- Otherwise, duplication detected!
    else
      -- First duplicate: Set name, and position of first definition
      if duplicates[ast[i].name] == nil then
        duplicates[ast[i].name] = {}
        duplicates[ast[i].name][#duplicates[ast[i].name] + 1] = firstPositions[ast[i].name]
      end
      
      -- First and subsequent duplicates, add position of this duplicate
      duplicates[ast[i].name][#duplicates[ast[i].name] + 1] = ast[i].position
    end
  end

  local entryPoint = self.variables[literals.entryPointName]
  if not entryPoint then
    self:addError('No entry point found. (Program must contain a function named "entry point.")')
  else
    local eppCount = #entryPoint.type_.parameters
    if eppCount > 0 then
      self:addError('Entry point has '..common.toReadableNumber(eppCount, 'parameter')..' but should have none.', entryPoint.type_.parameters[1])
    end
  end

  -- Report error. Since we list the number of duplicates, we do this as a second pass.
  for name, duplicate_positions in pairs(duplicates) do
    if #duplicate_positions > 0 then
      self:addError(#duplicate_positions .. ' duplicate top-level variables sharing name "'..name..'."')
      for index,position in ipairs(duplicate_positions) do
        self:addError(index .. ': ', {position=position})
      end
    end
  end

  local entryPoint = nil
  for i = 1,#ast do
    self:codeNewVariable(ast[i])
  end
  -- 

  local fakeEntryPointNode = {name=literals.entryPointName}  
  self:codeLoadVariable(fakeEntryPointNode)
  self:addCode('callFunction')

  self.currentCode.version = common.toStackVMVersionHash()

  return self.currentCode
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