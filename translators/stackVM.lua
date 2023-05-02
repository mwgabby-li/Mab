local module = {}
local literals = require 'literals'
local l_op = literals.op

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
    if self.functions[ast.value] then
      self:addError('Reading from variable "'..ast.value..'" with the same name as a function.', ast) 
    end

    if self.variables[ast.value] == nil then
      self:addError('Trying to load from undefined variable "' .. ast.value .. '."', ast) 
    end
    self:addCode('load')
    self:addCode(self:variableToNumber(ast.value))
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
    self:addCode('store')
    self:addCode(self:variableToNumber(ast.writeTarget.value))
  elseif writeTarget.tag == 'arrayElement' then
    self:codeExpression(ast.writeTarget.array)
    self:codeExpression(ast.writeTarget.index)
    self:codeExpression(ast.assignment)
    self:addCode('setArray')
  else
    self:addError('Unknown write target type, tag was "'..tostring(ast.tag)..'."')
  end
end

function Translator:codeStatement(ast)
  if ast.tag == 'emptyStatement' then
    return
  elseif ast.tag == 'statementSequence' then
    self:codeStatement(ast.firstChild)
    self:codeStatement(ast.secondChild)
  elseif ast.tag == 'return' then
    self:codeExpression(ast.sentence)
    self:addCode('return')
  elseif ast.tag == 'assignment' then
    self:codeAssignment(ast)
  elseif ast.tag == 'if' then
    -- Expression and jump
    self:codeExpression(ast.expression)
    local skipIfFixup = self:addJump('jumpIfFalse')
    -- Inside of if
    self:codeStatement(ast.block)
    if ast.elseBlock then
      -- If else, we need an instruction at the end of
      -- the 'if' block to jump past the 'else' block
      local skipElseFixup = self:addJump('jump')

      -- And our target for failing the 'if' is this 'else,'
      -- so set its target here after the jump to the end of 'else.'
      self:fixupJump(skipIfFixup)
      -- Fill out the 'else'
      self:codeStatement(ast.elseBlock)

      -- Finally, set the 'skip else' jump to here, after the 'else' block
      self:fixupJump(skipElseFixup)
    else
      self:fixupJump(skipIfFixup)
    end
  elseif ast.tag == 'while' then
    local whileStart = self:currentInstructionIndex()
    self:codeExpression(ast.expression)
    local skipWhileFixup = self:addJump 'jumpIfFalse'
    self:codeStatement(ast.block)
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
  local functionCode = {}
  self.currentCode = functionCode
  self:codeStatement(ast.block)
  if functionCode[#functionCode] ~= 'return' then
    self:addCode('push')
    self:addCode(0)
    self:addCode('return')
  end
  self.currentCode = nil
  self.functions[ast.name] = { code = functionCode }
end

function Translator:translate(ast)
  if ast.version ~= 2 then
    self:addError("Aborting stack VM translation, AST version doesn't match. Update stack VM translation!", ast)
    return nil, self.errors
  end
  
  local duplicates = { name }

  for i = 1,#ast do
    if self.functions[ast[i].name] ~= nil then
      -- First duplicate: Set name, and previous position
      if #duplicates == 0 then
        duplicates['name'] = ast[i].name
        duplicates[#duplicates + 1] = self.functions[ast[i].name]
      end
      
      -- First and subsequent duplicates, add position of this duplicate
      duplicates[#duplicates + 1] = ast[i].position
    end
    self.functions[ast[i].name] = ast[i].position
  end

  if #duplicates > 0 then
    self:addError(#duplicates .. ' duplicate functions sharing name "'..duplicates.name..'."')
    for index,position in ipairs(duplicates) do
      self:addError(index .. ': ', {position=position})
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
    entryPoint.code.version = 1 + ast.version
    return entryPoint.code, self.errors
  end
end

function module.translate(ast)
  local translator = Translator:new()
  return translator:translate(ast)
end

return module