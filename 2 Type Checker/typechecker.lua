local module = {}
local l_op = require('literals').op
local common = require 'common'

local TypeChecker = {}

TypeChecker.typeCompatibleBinaryOps = {
  boolean = {
    [l_op.equal] = true,
    [l_op.notEqual] = true,
    [l_op.and_] = true,
    [l_op.or_] = true,
  },
  number = {
    [l_op.add] = true,
    [l_op.subtract] = true,
    [l_op.multiply] = true,
    [l_op.divide] = true,
    [l_op.modulus] = true,
    [l_op.exponent] = true,
    [l_op.less] = true,
    [l_op.greater] = true,
    [l_op.lessOrEqual] = true,
    [l_op.greaterOrEqual] = true,
    [l_op.equal] = true,
    [l_op.notEqual] = true,
    -- To-Do: Bit manipulation?
    --[[
    [l_op.and_] = true,
    [l_op.or_] = true,
    --]]
  },
  
  unknown = {
    -- Unknown is really not compatible with anything...
    -- To-Do: Bit manipulation?
    --[[
    [l_op.and_] = true,
    [l_op.or_] = true,
    --]]
    --[[
    [l_op.equal] = true,
    [l_op.notEqual] = true,
    ]]
  },
}

TypeChecker.typeCompatibleUnaryOps = {
  boolean = {
    [l_op.positive] = true,
    [l_op.not_] = true,
  },
  
  number = {
    [l_op.negate] = true,
    -- To-Do: Bit manipulation?
    --[[
    [l_op.not_] = true,
    --]]
  },

  unknown = {
    -- Unknown is really not compatible with anything...
    -- To-Do: Bit manipulation?
    --[[
    [l_op.not_] = true,
    --]]
  },
}
    
TypeChecker.resultTypeBinaryOps = {
  number = {
    [l_op.add] = 'number',
    [l_op.subtract] = 'number',
    [l_op.multiply] = 'number',
    [l_op.divide] = 'number',
    [l_op.modulus] = 'number',
    [l_op.exponent] = 'number',
    [l_op.less] = 'boolean',
    [l_op.greater] = 'boolean',
    [l_op.lessOrEqual] = 'boolean',
    [l_op.greaterOrEqual] = 'boolean',
    [l_op.equal] = 'boolean',
    [l_op.notEqual] = 'boolean',
    -- To-Do: Bit manipulation?
    --[[
    [l_op.and_] = 'number',
    [l_op.or_] = 'number',
    --]]
  },

  boolean = {
    [l_op.equal] = 'boolean',
    [l_op.notEqual] = 'boolean',
    [l_op.not_] = 'boolean',
    [l_op.and_] = 'boolean',
    [l_op.or_] = 'boolean',
  },

  unknown = {
    -- Unknown really shouldn't be resulting in anything...
    --[[
    [l_op.equal] = 'boolean',
    [l_op.notEqual] = 'boolean',
    --]]
  }
}
TypeChecker.resultTypeUnaryOps = {
  number = {
    [l_op.positive] = 'number',
    [l_op.negate] = 'number',
    -- To-Do: Bit manipulation?
    --[[
    [l_op.not_] = 'number',
    --]]
  },
  boolean = {
    [l_op.not_] = 'boolean',
  },
}


function TypeChecker:new(o)
  o = o or {
    currentFunction = '',
    variableTypes = {},
    blocks = {},
    functions = {},
    errors = {},
  }
  self.__index = self
  setmetatable(o, self)
  return o
end

function TypeChecker:addError(message, ast)
  self.errors[#self.errors + 1] = {
    message = message,
    position = ast.position,
  }
end

function TypeChecker:createType(name, dimension)
  dimension = dimension or 0
  return {name=name, dimension=dimension}
end

function TypeChecker:duplicateType(variable)
  -- Check locals
  for i = #self.blocks,1, -1 do
    local typeOfVariable = self.blocks[i].locals[variable]
    if typeOfVariable then
      return self:createType(typeOfVariable.name, typeOfVariable.dimension)
    end
  end

  -- Check parameters
  for i = 1,#self.currentParameters do
    if self.currentParameters[i] then
      return self:createType(self.currentParameters[i].typeExpression.typeName)
    end
  end

  -- Check globals
  local global = self.variableTypes[variable]
  if global then
    return self:createType(self.variableTypes[variable].name, self.variableTypes[variable].dimension)
  end
end

function TypeChecker:typeMatches(typeTable, nameOrTypeTable)
  if typeTable == nil then
    return false
  end
  
  if typeTable.name == nameOrTypeTable then
    return true
  elseif type(nameOrTypeTable) == 'table' then
    return (typeTable.name == nameOrTypeTable.name) and
           (typeTable.dimension == nameOrTypeTable.dimension)
  else
    return false
  end
end

function TypeChecker:toResultType(op, binary, typeTable)
  if typeTable.dimension > 0 then
    return nil
  end
  
  if binary then
    return self:createType(self.resultTypeBinaryOps[typeTable.name][op])
  else
    return self:createType(self.resultTypeUnaryOps[typeTable.name][op])
  end
end

function TypeChecker:isCompatible(op, binary, typeTable)
  if typeTable.dimension > 0 then
    return false
  end
  
  if binary then
    return self.typeCompatibleBinaryOps[typeTable.name][op]
  else
    return self.typeCompatibleUnaryOps[typeTable.name][op]
  end
end

function TypeChecker:toReadable(typeTable)
  if typeTable == nil then
    return 'invalid type'
  elseif typeTable.dimension == 0 then
    return typeTable.name
  else
    local dimensionString = typeTable.dimension == 1 and '' or typeTable.dimension .. 'D '
    return dimensionString .. 'array of '.. typeTable.name ..'s'
  end
end

function TypeChecker:checkFunctionCall(ast)
  -- 
  for i=1,#ast.arguments do
    local parameter = self.functions[ast.name].parameters[i]
    local parameterType = self:createType(parameter.typeExpression.typeName)
    local argumentType = self:checkExpression(ast.arguments[i])
    if not self:typeMatches(parameterType, argumentType) then
        self:addError('Argument '..common.toReadableNumber(i)..' to function "' .. ast.name .. '" evaluates to type "'..
                      self:toReadable(argumentType)..'," but parameter "'..parameter.name..'" is type "'..
                      self:toReadable(parameterType)..'."', ast.arguments[i])
    end
  end

  return self.functions[ast.name].returnType
end

function TypeChecker:checkExpression(ast)
  if ast.tag == 'number' or ast.tag == 'boolean' then
    return self:createType(ast.tag)
  elseif ast.tag == 'functionCall' then
    return self:checkFunctionCall(ast)
  elseif ast.tag == 'variable' then
    local variableType = self:duplicateType(ast.value)
    
    if variableType == nil then
      self:addError('Attempting to use undefined variable "'..ast.value..'."', ast)
    end

    return variableType, ast.value
  elseif ast.tag == 'newArray' then
    local sizeType = self:checkExpression(ast.size)
    if not self:typeMatches(sizeType, self:createType('number')) then
      self:addError('Creating a new array indexed with "' ..
                    sizeType.name .. '", only "number" is allowed. Sorry!', ast)
    end

    local initType = self:checkExpression(ast.initialValue)
    return self:createType(initType.name, initType.dimension + 1)
  elseif ast.tag == 'arrayElement' then
    local indexType = self:checkExpression(ast.index)
    if not self:typeMatches(indexType, 'number') then
      indexType = indexType or 'nil'
      self:addError('Array indexing with type "' ..
                    self:toReadable(indexType) .. '", only "number" is allowed. Sorry!', ast)
    end

    local arrayType, variableName = self:checkExpression(ast.array)
    
    arrayType.dimension = arrayType.dimension - 1
    return arrayType, variableName
  elseif ast.tag == 'binaryOp' then
    -- If type checking fails on one of the subexpressions,
    -- don't bother reporting another error here, it will be nonsense.
    local firstChildType = self:checkExpression(ast.firstChild)
    if firstChildType == nil then
      return nil
    end

    local secondChildType = self:checkExpression(ast.secondChild)
    if secondChildType == nil then
      return nil
    end

    if not self:typeMatches(firstChildType, secondChildType) then
      self:addError('Mismatched types with operator "' .. ast.op ..
                    '"! (' .. self:toReadable(firstChildType) .. ' ' .. ast.op ..
                    ' ' .. self:toReadable(secondChildType) .. ').', ast)
      return nil
    end
    local expressionType = firstChildType
    -- is binary op? - true
    if not self:isCompatible(ast.op, true, expressionType) then
      self:addError('Operator "' .. ast.op .. '" cannot be used with type "' ..
                    self:toReadable(expressionType) .. '."', ast)
      return nil
    else
      -- is binary op? - true
      return self:toResultType(ast.op, true, expressionType)
    end
  elseif ast.tag == 'unaryOp' then
    local childType = self:checkExpression(ast.child)
    -- is binary op? - false (unary op)
    if not self:isCompatible(ast.op, false, childType) then
      self:addError('Operator "' .. ast.op .. '" cannot be used with type "' ..
                    self:toReadable(childType) .. '."', ast)
      return nil
    else
      -- is binary op? - false (unary op)
      return self:toResultType(ast.op, false, childType)
    end
  else
    self:addError('Unknown expression node tag "' .. ast.tag .. '."', ast)
    return self:createType('unknown')
  end
end

function TypeChecker:checkNewVariable(ast)
  local specifiedType = self:createType(ast.typeExpression.typeName)
  local inferredType = specifiedType

  -- Possibilities:
  -- No type specified:
  if self:typeMatches(specifiedType, 'unknown') then
    -- Assignment?
    if ast.assignment then
      -- Set the type to the assignment value.
      inferredType = self:checkExpression(ast.assignment)
      if inferredType == nil or self:typeMatches(inferredType, 'unknown') then
        self:addError('Cannot determine type of variable "'..ast.value..'" because no type was specified and the assignment has no type.', ast)
      end
    -- No assignment?
    else
      -- This is not currently allowed.
      self:addError('Cannot determine type of variable "'..ast.value..'" because no type was specified and no assignment was made.', ast)
    end

  -- Type specified and assignment.
  elseif ast.assignment then
    -- MUST MATCH.
    assignmentType = self:checkExpression(ast.assignment)
    if not self:typeMatches(specifiedType, assignmentType) then
      self:addError('Type of variable is ' .. self:toReadable(specifiedType), ast.typeExpression)
      self:addError('But variable is being initialized with ' .. self:toReadable(assignmentType), ast)
    end
    
  -- Type specified, no assignment.
  --  This is OK.
  else
    -- No action.
  end

  if ast.scope == 'global' then
    self.variableTypes[ast.value] = inferredType
  else
    self.currentBlock.locals[ast.value] = inferredType
  end
end

function TypeChecker:checkStatement(ast)
  if ast.tag == 'emptyStatement' then
    return
  elseif ast.tag == 'block' then
    self.blocks[#self.blocks + 1] = { locals = {} }
    self.currentBlock = self.blocks[#self.blocks]
    self:checkStatement(ast.body)
    self.blocks[#self.blocks] = nil
    self.currentBlock = self.blocks[#self.blocks]
  elseif ast.tag == 'newVariable' then
    self:checkNewVariable(ast)
  elseif ast.tag == 'statementSequence' then
    self:checkStatement(ast.firstChild)
    self:checkStatement(ast.secondChild)
  elseif ast.tag == 'return' then
    local returnType = self:checkExpression(ast.sentence)
    if returnType == nil then
      self:addError('Could not determine type of return type.', ast)
    elseif returnType.dimension > 0 then
      self:addError('Trying to return an array type "'.. self:toReadable(returnType) .. '." Disallowed, sorry!', ast)
    elseif not self:typeMatches(returnType, self.functions[self.currentFunction].returnType) then
      self:addError('Mismatched types with return, function "' .. self.currentFunction .. '" returns "' ..
                    self:toReadable(self.functions[self.currentFunction].returnType) .. '," but returning type "' ..
                    self:toReadable(returnType) .. '."', ast)
    end
  elseif ast.tag == 'functionCall' then
    -- Actually, we can just ignore this. It doesn't need to match anything.
  elseif ast.tag == 'assignment' then
    -- Get the type of the thing we're writing to, and its root name
    -- (e.g. given a single-dimension array of numbers 'a,'
    --  'a[12]' is the target, the type is {name='number', dimension=0},
    --  and the root name is 'a.')
    local writeTargetType, writeTargetRootName = self:checkExpression(ast.writeTarget)
    
    -- Get the type of the source of the assignment
    local expressionType = self:checkExpression(ast.assignment)
  
    if not self:typeMatches(writeTargetType, expressionType) then
      self:addError('Attempted to change type from "' ..
                    self:toReadable(writeTargetType) .. '" to "' ..
                    self:toReadable(expressionType) .. '." Disallowed, sorry!', ast)
    end
  elseif ast.tag == 'if' then
    local expressionType = self:checkExpression(ast.expression)

    if not self:typeMatches(expressionType, 'boolean') then
      self:addError('if statements require a boolean value,' ..
                    ' or an expression evaluating to a boolean.', ast)
    end
    self:checkStatement(ast.body)
    if ast.elseBody then
      self:checkStatement(ast.elseBody)
    end
  elseif ast.tag == 'while' then
    local expressionType = self:checkExpression(ast.expression)
    if not self:typeMatches(expressionType, 'boolean') then
      self:addError('while loop conditionals require a boolean value,' ..
                    ' or an expression evaluating to a boolean.', ast)
    end
    self:checkStatement(ast.body)
  elseif ast.tag == 'print' then
    self:checkExpression(ast.toPrint)
  else
    self:addError('Unknown statement node tag "' .. ast.tag .. '."', ast)
  end
end

function TypeChecker:checkFunction(ast)
  self.currentFunction = ast.name
  self.currentParameters = ast.parameters
  self:checkStatement(ast.block)
end

function TypeChecker:check(ast)
  for i = 1, #ast do
    local returnType = self:createType(ast[i].typeExpression.typeName)
    if self.functions[ast[i].name] == nil then
      self.functions[ast[i].name] = { returnType = returnType, parameters=ast[i].parameters }
    elseif not self:typesMatch(self.functions[ast[i].name].returnType, returnType) then
      self:addError('Function "' .. ast[i].name .. '" redefined with type "' .. self:toReadable(returnType) ..
                    ', was "' .. self:toReadable(self.functions[ast[i].name].returnType)..'."')
    end
    
    -- Check type of default argument expression against last parameter
    if ast[i].defaultArgument then
      -- No last parameter? This is also an error.
      local defaultArgumentType = self:checkExpression(ast[i].defaultArgument)
      local numParameters = #ast[i].parameters
      if numParameters == 0 then
        self:addError('Function "' .. ast[i].name .. '" has a default argument but no parameters.', ast[i])
      else
        local lastParameter = ast[i].parameters[numParameters]
        local parameterType = self:createType(lastParameter.typeExpression.typeName)
        if not self:typeMatches(defaultArgumentType,parameterType) then
        self:addError('Default argument for function "' .. ast[i].name .. '" evaluates to type "'..
                      self:toReadable(defaultArgumentType)..'," but parameter "'..lastParameter.name..'" is type "'..
                      self:toReadable(parameterType)..'."', lastParameter)
        end
      end
    end
  end

  for i = 1, #ast do
    self:checkFunction(ast[i])
  end
end

function module.check(ast)
  local typeChecker = TypeChecker:new()
  typeChecker:check(ast)
  return typeChecker.errors
end

return module