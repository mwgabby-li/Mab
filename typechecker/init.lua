local module = {}
local l_op = require('literals').op

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
    variableTypes = {},
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
  local current = self.variableTypes[variable]
  if current then
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

function TypeChecker:addVariable(identifier, typeOfIdentifier)
  -- To-Do: Scope?
  self.variableTypes[identifier] = typeOfIdentifier
end

function TypeChecker:checkExpression(ast, undefinedVariableOK)
  if ast.tag == 'number' or ast.tag == 'boolean' then
    return self:createType(ast.tag)
  elseif ast.tag == 'variable' then
    local variableType = self:duplicateType(ast.value)
    
    if variableType == nil and not undefinedVariableOK then
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

function TypeChecker:checkStatement(ast)
  if ast.tag == 'emptyStatement' then
    return
  elseif ast.tag == 'statementSequence' then
    self:checkStatement(ast.firstChild)
    self:checkStatement(ast.secondChild)
  elseif ast.tag == 'return' then
    local returnType = self:checkExpression(ast.sentence)
    if returnType.dimension > 0 then
      self:addError('Trying to return an array type "'.. self:toReadable(returnType) .. '." Disallowed, sorry!', ast)
    end
  elseif ast.tag == 'assignment' then
    -- Get the type of the thing we're writing to, and its root name
    -- (e.g. given a single-dimension array of numbers 'a,'
    --  'a[12]' is the target, the type is {name='number', dimension=0},
    --  and the root name is 'a.')
    -- undefined variable OK: true, assignments are the only case where this is allowed.
    local writeTargetType, writeTargetRootName = self:checkExpression(ast.writeTarget, true)
    
    -- Get the type of the source of the assignment
    local expressionType = self:checkExpression(ast.assignment)
  
    -- If the thing we're writing to has a type and that type is 'unknown,' with a matching dimension,
    -- this assignment is allowed to set its type.
    if writeTargetType == nil then
      -- This variable doesn't yet exist
      self:addVariable(writeTargetRootName, expressionType)
    -- Variable exists, and its type is 'unknown?'
    elseif self:typeMatches(writeTargetType, 'unknown') and
           writeTargetType.dimension == expressionType.dimension then
        writeTargetType = expressionType
        self.variableTypes[writeTargetRootName].name = writeTargetType.name
    -- However, if the write target exists already and its type does not match
    elseif not self:typeMatches(writeTargetType, expressionType) then
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
    self:checkStatement(ast.block)
    if ast.elseBlock then
      self:checkStatement(ast.elseBlock)
    end
  elseif ast.tag == 'while' then
    local expressionType = self:checkExpression(ast.expression)
    if not self:typeMatches(expressionType, 'boolean') then
      self:addError('while loop conditionals require a boolean value,' ..
                    ' or an expression evaluating to a boolean.', ast)
    end
    self:checkStatement(ast.block)
  elseif ast.tag == 'print' then
    self:checkExpression(ast.toPrint)
  else error 'invalid tree'
  end
end

function TypeChecker:checkFunction(ast)
  self:checkStatement(ast.block)
end

function TypeChecker:check(ast)
  if ast.version ~= 2 then
    self:addError("Aborting type check, AST version doesn't match. Update type checker!", ast)
    return
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