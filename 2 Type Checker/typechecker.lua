local module = {}
local literals = require'literals'
local l_op = literals.op
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

  string = {},

  array = {},

  ['function'] = {},

  none = {},
}

TypeChecker.typeCompatibleUnaryOps = {
  boolean = {
    [l_op.not_] = true,
  },
  
  number = {
    [l_op.positive] = true,
    [l_op.negate] = true,
    -- To-Do: Bit manipulation?
    --[[
    [l_op.not_] = true,
    --]]
  },

  string = {},

  array = {},

  ['function'] = {},

  none = {},
}

function TypeChecker:isCompatible(op, binary, type_)
  if binary then
    return self.typeCompatibleBinaryOps[type_.tag][op]
  else
    return self.typeCompatibleUnaryOps[type_.tag][op]
  end
end

function readOnlyTable(table)
   return setmetatable({}, {
     __index = table,
     __newindex = function(_table, _key, _value)
                    error("Attempt to modify read-only table")
                  end,
     __metatable = false
   });
end

local kBooleanType = readOnlyTable{tag='boolean'}
local kNumberType = readOnlyTable{tag='number'}
local kNoType = readOnlyTable{tag='none'}

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

  string = {},

  array = {},

  ['function'] = {},

  -- None doesn't result in anything.
  none = {}
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

  string = {},

  array = {},

  ['function'] = {},

  -- None doesn't result in anything.
  none = {}
}

function TypeChecker:toResultType(op, binary, type_)
  local resultTag
  if binary then
    resultTag = self.resultTypeBinaryOps[type_.tag][op]
  else
    resultTag = self.resultTypeUnaryOps[type_.tag][op]
  end
  return self:createBasicType(not resultTag and 'none' or resultTag)
end

function cloneDimensions(toClone)
  if toClone then
    local clone = {}
    for i=1,#toClone do
      clone[i] = toClone[i]
    end
    return clone
  else
    return false
  end
end

function TypeChecker:new(o)
  o = o or {
    currentFunction = { parameters = {} },
    variableTypes = {},
    blocks = {},
  }
  self.__index = self
  setmetatable(o, self)
  return o
end

function isBasicType(tag)
  return tag == 'number' or tag == 'boolean' or tag == 'string' or tag == 'none'
end

function isSpecialType(tag)
  return tag == 'none' or tag == 'infer'
end

function TypeChecker:addError(...)
  if self.errorReporter then
    self.errorReporter:addError(...)
  end
end

function TypeChecker:createBasicType(tag)
  return {tag=tag}
end

function TypeChecker:createArrayType(dimensions, elementType)
  return {tag='array', dimensions=dimensions, elementType=elementType}
end

function TypeChecker:getVariablesType(variable)
  -- Check locals
  for i = #self.blocks,1, -1 do
    local typeOfVariable = self.blocks[i].locals[variable]
    if typeOfVariable then
      return typeOfVariable
    end
  end

  -- Check parameters
  for i = 1,#self.currentFunction.parameters do
    local parameter = self.currentFunction.parameters[i]
    if parameter.name == variable then
      return parameter.type_
    end
  end

  -- Check globals
  local global = self.variableTypes[variable]
  if global then
    return global
  end

  return kNoType
end

function TypeChecker:typeValid(apple, allowNone)
  if apple.tag == 'none' and not allowNone then
    return false
  end

  if apple.dimensions then
    for i=1,#apple.dimensions do
      -- e.g. the dimensions are 'invalid'
      if type(apple.dimensions[i]) == 'string' then
        return false
      end
    end
  end
  return true
end

function TypeChecker:typeMatches(apple, orange, allowNone)
  if not self:typeValid(apple, allowNone) or not self:typeValid(orange, allowNone) then
    return false
  end
  
  if apple.tag ~= orange.tag then
    return false
  end
  
  if apple.tag == 'array' then
    if apple.elementType.tag ~= orange.elementType.tag then
      return false
    end
    if #apple.dimensions ~= #orange.dimensions then
      return false
    end
    for i=1,#apple.dimensions do
      if type(apple.dimensions[i]) == 'string' or type(orange.dimensions[i]) == 'string' then
        return false
      end

      if apple.dimensions[i] ~= orange.dimensions[i] then
        return false
      end
      return true
    end
  elseif isBasicType(apple.tag) then
    return true
  elseif apple.tag == 'function' then
    if #apple.parameters ~= #orange.parameters then
      return false
    end
    
    for i=1, #apple.parameters do
      if not self:typeMatches(apple.parameters[i].type_, orange.parameters[i].type_) then
        return false
      end
    end
    if not self:typeMatches(apple.resultType, orange.resultType) then
      return false
    end
    
    return true
  else
    self:addError('Internal error: Unknown type tag "'..apple.tag..'."')
    return false
  end

  return true
end

function TypeChecker:checkFunctionCall(ast)
  local functionType, rootName = self:checkExpression(ast.target)

  if #ast.arguments ~= #functionType.parameters then
    -- Don't try type checking, this is another phase's error.
    return functionType.resultType
  end

  for i=1,#ast.arguments do
    local parameter = functionType.parameters[i]
    local parameterType = parameter.type_
    local argumentType = self:checkExpression(ast.arguments[i])
    if not self:typeMatches(parameterType, argumentType) then
      self:addError('Argument '..common.toReadableNumber(i)..' to function called via "' .. rootName.. '" evaluates to type "'..
                    common.toReadableType(argumentType)..'," but parameter "'..parameter.name..'" is type "'..
                    common.toReadableType(parameterType)..'."', ast.arguments[i])
    end
  end

  return functionType.resultType
end

-- Wrapper that tags the expression with the resulting type.
function TypeChecker:checkExpression(ast)
  local type_, name = self:checkExpressionInner(ast)
  ast.type_ = type_
  return type_, name
end

-- Returns type and optionally name.
-- Call checkExpression(), don't call this directly.
function TypeChecker:checkExpressionInner(ast)
  -- Things like literal numbers, booleans, or strings.
  if isBasicType(ast.tag) then
    return self:createBasicType(ast.tag)
  elseif ast.tag == 'functionCall' then
    return self:checkFunctionCall(ast)
  elseif ast.tag == 'variable' then
    local variableType = self:getVariablesType(ast.name)
    
    if not self:typeValid(variableType) then
      self:addError('Attempting to use undefined variable "'..ast.name..'."', ast)
    end

    return variableType, ast.name
  elseif ast.tag == 'newArray' then
    local sizeType = self:checkExpression(ast.size)
    if not self:typeMatches(sizeType, kNumberType) then
      self:addError('Creating a new array indexed with "' ..
                    sizeType.tag .. '", only "number" is allowed. Sorry!', ast.size)
    end
    
    -- Set size to a special 'invalid' value if the array's not indexed with a number.
    local size = ast.size.value or 'invalid'
    if ast.size.tag ~= 'number' then
      self:addError('New arrays must be created with literal numbers. Sorry!', ast)
    end

    local initType = self:checkExpression(ast.initialValue)
    
    -- If the init type is an array, the new dimensions have one more element.
    -- Otherwise, the new dimensions are 1D with the size equal to the value.
    local newDimensions = {size}
    local elementType
    if initType.dimensions then
      -- Copy dimensions first to last into new dimensions:
      local clonedDimensions = cloneDimensions(initType.dimensions)
      for i=1,#clonedDimensions do
        newDimensions[#newDimensions + 1] = clonedDimensions[i]
      end
      elementType = initType.elementType
    else
      elementType = initType
    end

    return self:createArrayType(newDimensions, elementType)
  elseif ast.tag == 'arrayElement' then
    local indexType = self:checkExpression(ast.index)
    if not self:typeMatches(indexType, kNumberType) then
      indexType = indexType or tostring(indexType)
      self:addError('Array indexing with type "' ..
                    common.toReadableType(indexType) .. '", only "number" is allowed. Sorry!', ast)
    end

    local arrayType, variableName = self:checkExpression(ast.array)

    if arrayType.tag ~= 'array' then
      self:addError('Attempting to index into "'..variableName..'," which is a "'..
                    arrayType.tag..'," not an array.', ast.array)
      -- EARLY RETURN, can't recover.
      return arrayType, variableName
    end

    local newDimensions = cloneDimensions(arrayType.dimensions)

    -- The array index removes the first dimensions,
    -- so we have to move everything over.
    for i=1,#newDimensions - 1 do
      newDimensions[i] = newDimensions[i+1]
    end
    -- Then nil out the last element so we're one less dimension.
    newDimensions[#newDimensions] = nil

    local resultType
    if next(newDimensions) == nil then
      resultType = arrayType.elementType
    else
      resultType = self:createArrayType(newDimensions, arrayType.elementType)
    end

    return resultType, variableName
  elseif ast.tag == 'binaryOp' then
    -- If type checking fails on one of the subexpressions,
    -- don't bother reporting another error here, it will be nonsense.
    local firstChildType = self:checkExpression(ast.firstChild)
    if not self:typeValid(firstChildType) then
      return kNoType
    end

    local secondChildType = self:checkExpression(ast.secondChild)
    if not self:typeValid(secondChildType) then
      return kNoType
    end

    if not self:typeMatches(firstChildType, secondChildType) then
      self:addError('Mismatched types with operator "' .. ast.op ..
                    '"! (' .. common.toReadableType(firstChildType) .. ' ' .. ast.op ..
                    ' ' .. common.toReadableType(secondChildType) .. ').', ast)
      return kNoType
    end
    local expressionType = firstChildType
    -- is binary op? - true
    if not self:isCompatible(ast.op, true, expressionType) then
      self:addError('Operator "' .. ast.op .. '" cannot be used with type "' ..
                    common.toReadableType(expressionType) .. '."', ast)
      return kNoType
    else
      -- is binary op? - true
      return self:toResultType(ast.op, true, expressionType)
    end
  elseif ast.tag == 'unaryOp' then
    local childType = self:checkExpression(ast.child)
    -- is binary op? - false (unary op)
    if not self:isCompatible(ast.op, false, childType) then
      self:addError('Operator "' .. ast.op .. '" cannot be used with type "' ..
                    common.toReadableType(childType) .. '."', ast)
      return kNoType
    else
      -- is binary op? - false (unary op)
      return self:toResultType(ast.op, false, childType)
    end
  elseif ast.tag == 'ternary' then
    local testType = self:checkExpression(ast.test)
    if not self:typeMatches(testType, kBooleanType) then
      self:addError('Ternary condition expression must evaluate to boolean.\n'..
                    'This expression evaluates to "'..common.toReadableType(testType)..
                    '."', ast.testPosition)
    end

    local trueBranchType = self:checkExpression(ast.trueExpression)
    local falseBranchType = self:checkExpression(ast.falseExpression)
    if not self:typeMatches(trueBranchType, falseBranchType) then
      self:addError('The two branches of the ternary operator must have the same type.\n'..
                    ' Currently, the type of the true branch is "'..
                    common.toReadableType(trueBranchType)..
                    ',"\n and the type of the false branch is "'..
                    common.toReadableType(falseBranchType)..'."\n'..
                    ' Further type checks in this run will assume this evaluated to "'..
                    common.toReadableType(trueBranchType)..'."', ast)
    end

    -- Assume true branch type.
    return trueBranchType
  else
    self:addError('Unknown expression node tag "' .. ast.tag .. '."', ast)
    return kNoType
  end
end

function TypeChecker:inferScope(ast)
  local result = ast.scope

  -- Unspecified scopes
  if result == 'unspecified' then
    -- Default to local after the outer block
    if #self.blocks > 0 then
      result = 'local'
    -- Default to global inside the outer block
    else
      result = 'global'
    end
  elseif ast.scope ~= 'global' and ast.scope ~= 'local' then
    if ast.scope ~= nil then
      self:addError('Unknown scope .."'..tostring(ast.scope)..'."', ast)
    else
      self:addError('Scope undefined.', ast)
    end
    result = 'local'
  end

  ast.scope = result

  return result
end

function TypeChecker:checkNewVariable(ast)
  local specifiedType = ast.type_
  local inferredType = specifiedType

  -- Possibilities:
  -- A function type:
  if specifiedType.tag == 'function' then
    if ast.assignment and ast.assignment.tag == 'block' then
      -- This is OK, a function is being assigned a block.
      -- TODO: Maybe check the return types?
      self:checkFunction(ast)
    -- Otherwise, function is being assigned some expression.
    elseif ast.assignment then
      -- More work for Lambdas... type may not be known.
      local assignmentType = self:checkExpression(ast.assignment)

      if not self:typeMatches(specifiedType, assignmentType) then
        self:addError('Type of variable is ' .. common.toReadableType(specifiedType) ..'.', ast.type_)
        self:addError('But variable is being initialized with ' .. common.toReadableType(assignmentType) .. '.', ast.assignment)
      end
    elseif not ast.assignment then
      -- Functions without default values are currently disallowed.
      self:addError('Function type specified for variable "'..ast.name..'", but no value was provided. Defaults required for functions, sorry!', ast)
    end
  -- We aren't inferring, but invalid type specified:
  elseif not specifiedType.tag == 'infer' and not self:typeValid(specifiedType) then
    self:addError('Type of variable "'..ast.name..'" specified, but type is invalid: "'..common.toReadableType(specifiedType)..'."', ast)
  -- No type specified:
  elseif specifiedType.tag == 'infer' then
    -- Assignment?
    if ast.assignment then
      -- Set the type to the assignment value.
      inferredType = self:checkExpression(ast.assignment)
      if not self:typeValid(inferredType) then
        self:addError('Cannot determine type of variable "'..ast.name..'" because no type was specified and the assignment has no type.', ast)
      end
    -- No assignment?
    else
      -- This is not currently allowed.
      self:addError('Cannot determine type of variable "'..ast.name..'" because no type was specified and no assignment was made.', ast)
    end

  -- Type specified and assignment.
  elseif ast.assignment then
    -- MUST MATCH.
    local assignmentType = self:checkExpression(ast.assignment)
    if not self:typeMatches(specifiedType, assignmentType) then
      self:addError('Type of variable is ' .. common.toReadableType(specifiedType) ..'.', ast.type_)
      self:addError('But variable is being initialized with ' .. common.toReadableType(assignmentType) .. '.', ast.assignment)
    end
    
  -- Type specified, no assignment.
  --  This is OK.
  else
    -- No action.
  end

  -- If this is a function type, and was inferred,
  -- we won't be able to code calls
  -- in the later translator unless it's stored here,
  -- so just overwrite the type in the AST.
  ast.type_ = inferredType
  
  if inferredType.tag == 'function' then
    if ast.name:match '^if ' or ast.name:match '^while ' then
      self:addError('"'..ast.name..'" starts with the conditional keyword "'..ast.name:match('^(.*) ')..'," and is type "'..common.toReadableType(inferredType)..'." Function types may not start with conditional keywords, sorry.', ast)
    end
  end

  if inferredType.tag == 'function' then
    if ast.name:match '^if ' or ast.name:match '^while ' then
      self:addError('"'..ast.name..'" starts with the conditional keyword "'..
                    ast.name:match('^(.*) ')..'," and is type "'..
                    common.toReadableType(inferredType)..
                    '." Function types may not start with conditional keywords, sorry.', ast)
    end
  end

  local scope = self:inferScope(ast)

  -- Unspecified scopes
  if scope == 'local' then
    self.currentBlock.locals[ast.name] = inferredType
  elseif scope == 'global' then
    self.variableTypes[ast.name] = inferredType
  else
    if scope ~= nil then
      self:addError('Unknown scope .."'..tostring(scope)..'."', ast)
    else
      self:addError('Scope undefined.', ast)
    end
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
  elseif ast.tag == 'functionCall' then
    self:checkFunctionCall(ast)
  elseif ast.tag == 'evalTo' then
    -- Check return
    if ast.target.tag == 'result' then
      local returnType = self:checkExpression(ast.expression)
      -- Allow none: true
      if not self:typeValid(returnType, true) then
        self:addError('Could not determine type of return type.', ast)
      -- Allow none: true
      elseif not self:typeMatches(returnType, self.currentFunction.resultType, true) then
        self:addError('Mismatched types with return, function "' .. self.currentFunction.name .. '" returns "' ..
                      common.toReadableType(self.currentFunction.resultType) .. '," but returning type "' ..
                      common.toReadableType(returnType) .. '."', ast)
      end
    -- Evaluate the expression, but discard the result:
    elseif ast.target.tag == 'none' then
      -- Because we're discarding the result, so it doesn't have to match anything,
      -- but the expression itself does have to be valid.
      self:checkExpression(ast.expression)
    -- This is an assignment:
    else
      -- Get the type of the thing we're writing to, and its root name
      -- (e.g. given a two-dimensional array of numbers of 4x4, 'a,'
      --  'a[1][2]' is the target, the type is {name='number', dimensions={4,4}},
      --  and the root name is 'a.')
      local targetType, targetRootName = self:checkExpression(ast.target)

      -- Get the type of the source of the assignment
      local expressionType, etRootName = self:checkExpression(ast.expression)
    
      if not self:typeMatches(targetType, expressionType) then
        local wttValid = self:typeValid(targetType)
        local etValid = self:typeValid(expressionType)
        
        if not wttValid and not etValid then
          local etMessage = etRootName and 'from "'..etRootName..'," because its type is invalid: "' or 'from an invalid type: "'
          self:addError('Sorry, cannot assign '..etMessage..
                        common.toReadableType(targetType)..
                        '."\nThe invalid type of "'..targetRootName..'," the assignment target, also prevents this: "'..
                        common.toReadableType(expressionType)..'."', ast)
        elseif not wttValid then
          self:addError('Sorry, cannot assign to "'..targetRootName..'" because its type is invalid: "' ..
                        common.toReadableType(targetType) .. '."', ast)
        elseif not etValid then
          local endOfMessage = etRootName and 'from "'..etRootName..'," because its type is invalid: "' or 'from an invalid type: "'
          
          self:addError('Sorry, cannot assign '..endOfMessage..
                        common.toReadableType(expressionType) .. '."', ast)
        elseif wttValid and etValid then
          self:addError('Attempted to change type from "' ..
                        common.toReadableType(targetType) .. '" to "' ..
                        common.toReadableType(expressionType) .. '." Disallowed, sorry!', ast)
        end
      end
    end
  elseif ast.tag == 'if' then
    local expressionType = self:checkExpression(ast.expression)

    if not self:typeMatches(expressionType, kBooleanType) then
      self:addError('if statements require a boolean value,' ..
                    ' or an expression evaluating to a boolean.'..
                    'Type was "'..common.toReadableType(expressionType)..'."', ast)
    end
    self:checkStatement(ast.body)
    if ast.elseBody then
      self:checkStatement(ast.elseBody)
    end
  elseif ast.tag == 'while' then
    local expressionType = self:checkExpression(ast.expression)
    if not self:typeMatches(expressionType, kBooleanType) then
      self:addError('while loop conditionals require a boolean value,' ..
                    ' or an expression evaluating to a boolean.'..
                    'Type was "'..common.toReadableType(expressionType)..'."', ast)
    end
    self:checkStatement(ast.body)
  elseif ast.tag == 'print' then
    self:checkExpression(ast.toPrint)
  elseif ast.tag == 'exit' then
    if not self:typeMatches(kNoType, self.currentFunction.resultType, true) then
      self:addError('Requested exit with no return value (with \'exit\' keyword), but function\'s result type is "'..
                    common.toReadableType(self.currentFunction.resultType)..'," not "none."')
    end
  else
    self:addError('Unknown statement node tag "' .. ast.tag .. '."', ast)
  end
end

function TypeChecker:checkFunction(ast)
  local previousFunction = self.currentFunction

  self.currentFunction = {
    name = ast.name,
    parameters = ast.type_.parameters,
    resultType = ast.type_.resultType,
  }

  self:checkStatement(ast.assignment)

  self.currentFunction = previousFunction
end

function TypeChecker:check(ast)

  -- Do a pre-pass, and add types for all functions to the AST.
  -- Two-pass compilation style for functions at the top level.
  for i = 1, #ast do
    local type_ = ast[i].type_
    if ast[i].tag == 'newVariable' and type_.tag == 'function' then
      -- Just infer the scope for the errors it generates...
      local scope = self:inferScope(ast[i])
      if scope ~= 'global' then
        -- TODO: Export?
        -- TODO: This only checks functions. But others should also be checked for this...
        self:addError('Top-level variables cannot use any scope besides global, which is the default.'..
                      ' Otherwise, they would be inaccessible.', ast[i])
        scope = 'global'
      end

      local name = ast[i].name
      local resultType = type_.resultType
      if self.variableTypes[name] == nil then
        self.variableTypes[name] = type_
      -- Error for a function being defined with two types. Errors in other parts of the compiler for duplicate function names...
      -- TODO: Overloading support, etc. No checks on function parameters and so on...
      elseif not self:typeMatches(self.variableTypes[name].resultType, resultType) then
        self:addError('Function "' .. name .. '" redefined returning type "' .. common.toReadableType(resultType) ..
                      '," was "' .. common.toReadableType(self.variableTypes[name].resultType)..'."')
      end

      -- Check type of default argument expression against last parameter
      if type_.defaultArgument then
        -- No last parameter? This is also an error.
        local defaultArgumentType = self:checkExpression(type_.defaultArgument)
        local numParameters = #type_.parameters
        if numParameters == 0 then
          self:addError('Function "'..name..'" has a default argument but no parameters.', ast[i])
        else
          local lastParameter = type_.parameters[numParameters]
          local parameterType = lastParameter.type_
          if not self:typeMatches(defaultArgumentType,parameterType) then
          self:addError('Default argument for function "'..name..'" evaluates to type "'..
                        common.toReadableType(defaultArgumentType)..'," but parameter "'..lastParameter.name..'" is type "'..
                        common.toReadableType(parameterType)..'."', lastParameter)
          end
        end
      end
    end
  end

  -- Make sure entry point returns a number.
  local entryPoint = self.variableTypes[literals.entryPointName]
  if entryPoint then
    if not self:typeMatches(entryPoint.resultType, kNumberType) then
      self:addError('Entry point must return a number because that\'s what OSes expect.', entryPoint.returnType)
    end
  end

  for i = 1, #ast do
    self:checkStatement(ast[i], true)
  end
end

function module.check(ast, parameters)
  local typeChecker = TypeChecker:new()
  typeChecker.errorReporter = common.ErrorReporter:new()
  if parameters then
    typeChecker.errorReporter.stopAtFirstError = parameters.stopAtFirstError
  end
  typeChecker.errorReporter:pcallAddErrorOnFailure(typeChecker.check, typeChecker, ast)
  return typeChecker.errorReporter,
         typeChecker.errorReporter:count() == 0
end

return module