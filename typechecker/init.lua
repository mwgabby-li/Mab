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

function TypeChecker:typeMatches(typeTable, nameOrTypeTable)
  if typeTable.name == nameOrTypeTable then
    return true
  elseif type(nameOrTypeTable) == type({}) then
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
    return self.resultTypeBinaryOps[typeTable.name][op]
  else
    return self.resultTypeUnaryOps[typeTable.name][op]
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
  if typeTable.dimension == 0 then
    return typeTable.name
  else
    return typeTable.name .. ('[]'):rep(typeTable.dimension)
  end
end

function TypeChecker:addVariable(identifier, typeOfIdentifier)
  -- To-Do: Scope?
  self.variableTypes[identifier] = typeOfIdentifier
end

function TypeChecker:checkExpression(ast)
  if ast.tag == 'number' or ast.tag == 'boolean' then
    return self:createType(ast.tag)
  elseif ast.tag == 'variable' then
    return self.variableTypes[ast.value]
  elseif ast.tag == 'newArray' then
    local sizeType = self:checkExpression(ast.size)
    if not self:typeMatches(sizeType, 'number') then
      sizeType = sizeType or 'nil'
      self:addError('Creating a new array with a size of type "' ..
                    self:toReadable(sizeType) .. '", only "number" is allowed. Sorry!', ast)
    end
    return self:createType('unknown', 1)
  elseif ast.tag == 'arrayElement' then
    local indexType = self:checkExpression(ast.index)
    if not self:typeMatches(indexType, 'number') then
      indexType = indexType or 'nil'
      self:addError('Indexing into "'.. ast.array ..' with type "' ..
                    self:toReadable(indexType) .. '", only "number" is allowed. Sorry!', ast)
    end
    -- To-Do: This needs to change for multi-dimensional arrays.
    return self:createType(self.variableTypes[ast.array.value].name)
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
                    ' ' .. self:toReadable(secondChildType) .. ')', ast)
      return nil
    end
    local expressionType = firstChildType
    -- is binary op? - true
    if not self:isCompatible(ast.op, true, expressionType) then
      self:addError('Operator "' .. ast.op .. '" cannot be used with type "' ..
                    self:toReadable(expressionType) .. '"!', ast)
      return nil
    else
      -- is binary op? - true
      return self:toResultType(ast.op, true, expressionType)
    end
  elseif ast.tag == 'unaryOp' then
    local childType = self:checkExpression(ast.child)
    -- is binary op? - false (unary op)
    if not isCompatible(ast.op, false, childType) then
      self:addError('Operator "' .. ast.op .. '" cannot be used with type "' ..
                    self:toReadable(firstChildType) .. '"!', ast)
      return nil
    else
      -- is binary op? - false (unary op)
      return self:toResultType(ast.op, false, expressionType)
    end
  else error 'invalid tree'
  end
end

function TypeChecker:checkStatement(ast)
  if ast.tag == 'emptyStatement' then
    return
  elseif ast.tag == 'statementSequence' then
    self:checkStatement(ast.firstChild)
    self:checkStatement(ast.secondChild)
  elseif ast.tag == 'return' then
    self:checkExpression(ast.sentence)
  elseif ast.tag == 'assignment' then
    -- Three cases.
    -- 1. We are assigning a value to a variable, such as a number of boolean.
    -- 2. We are assigning a value to an array element.
    -- 3. We are assigning an array to a variable.
    
    local arrayElement = ast.writeTarget.array ~= nil
    local variableName = arrayElement and ast.writeTarget.array.value or ast.writeTarget.value
    -- To-Do: This needs to change for multi-dimensional arrays.
    local variableType = nil
    local arrayType = nil
    if arrayElement then
      arrayType = self.variableTypes[variableName]
      variableType = self:createType(arrayType.name, 0)
    elseif self.variableTypes[variableName] then
      variableType = self.variableTypes[variableName]
      arrayType = variableType.dimension > 0 and variableType or nil
    end

    local expressionType = self:checkExpression(ast.assignment)
    if variableType ~= nil and self:typeMatches(variableType, 'unknown') then
      -- currently, only arrays can have an unknown type
      assert(arrayElement)
      variableType = self:createType(expressionType.name)
      self.variableTypes[variableName] = self:createType(expressionType.name, self.variableTypes[variableName].dimension)
    end

    -- No changing variable types for now
    if variableType ~= nil and not self:typeMatches(variableType, expressionType) then
      local deducedType = expressionType
      -- If this is an array element whose array already had a type
      if arrayElement then
        -- Notify of deduced type change (including array)
        deducedType = self:createType(deducedType.name, arrayType.dimension)
      end
      -- Otherwise, this is a normal type change
      
      self:addError('Attempted to change type of variable "'.. variableName ..'" from "' ..
                    self:toReadable(self.variableTypes[variableName]) .. '" to "' ..
                    self:toReadable(deducedType) .. '." Disallowed, sorry!', ast)
    -- This variable doesn't yet exist
    elseif variableType == nil then
      self:addVariable(variableName, expressionType)
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

function module.check(ast)
  local typeChecker = TypeChecker:new()
  typeChecker:checkStatement(ast)
  if #typeChecker.errors then
    return typeChecker.errors
  else
    return nil
  end
end

return module