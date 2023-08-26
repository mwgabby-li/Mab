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
    self:addError('ERROR TYPECHECK INTERNAL UNKNOWN TYPE TAG', {typeTag = apple.tag})
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
      self:addError('ERROR TYPECHECK PARAMETER ARGUMENT TYPE MISMATCH',
                    {number = common.toReadableNumber(i),
                     variableName=rootName, argumentTypeName = common.toReadableType(argumentType),
                     parameterName=parameter.name, parameterTypeName=common.toReadableType(parameterType)},
                     ast.arguments[i])
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
      self:addError('ERROR TYPECHECK USING UNDEFINED VARIABLE', {variableName=ast.name}, ast)
    end

    return variableType, ast.name
  elseif ast.tag == 'newArray' then
    local sizeType = self:checkExpression(ast.size)
    if not self:typeMatches(sizeType, kNumberType) then
      self:addError('ERROR TYPECHECK NEW ARRAY NON NUMERIC DIMENSION TYPE',
                    {indexedType=common.toReadableType(sizeType.tag)}, ast.size)
    end
    
    -- Set size to a special 'invalid' value if the array's not indexed with a number.
    local size = ast.size.value or 'invalid'
    if ast.size.tag ~= 'number' then
      self:addError('ERROR TYPECHECK NEW ARRAYS LITERAL ONLY', {}, ast)
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
      self:addError('ERROR TYPECHECK NON NUMERIC ARRAY INDEX',
                    {indexedType=common.toReadableType(indexType)}, ast)
    end

    local arrayType, variableName = self:checkExpression(ast.array)

    if arrayType.tag ~= 'array' then
      self:addError('ERROR TYPECHECK INDEXING NON ARRAY',
                    {variableName=variableName, arrayTypeTag=arrayType.tag}, ast.array)
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
      self:addError('ERROR TYPECHECK MISMATCHED TYPES WITH OPERATOR',
                    {operator=ast.op, firstType=common.toReadableType(firstChildType),
                     secondType=common.toReadableType(secondChildType)}, ast)
      return kNoType
    end
    local expressionType = firstChildType
    -- is binary op? - true
    if not self:isCompatible(ast.op, true, expressionType) then
      self:addError('ERROR TYPECHECK BINARY OPERATOR INVALID TYPE',
                    {operator=ast.op, type=common.toReadableType(expressionType)}, ast)
      return kNoType
    else
      -- is binary op? - true
      return self:toResultType(ast.op, true, expressionType)
    end
  elseif ast.tag == 'unaryOp' then
    local childType = self:checkExpression(ast.child)
    -- is binary op? - false (unary op)
    if not self:isCompatible(ast.op, false, childType) then
      self:addError('ERROR TYPECHECK UNARY OPERATOR INVALID TYPE',
                    {operator=ast.op, type=common.toReadableType(childType)}, ast)
      return kNoType
    else
      -- is binary op? - false (unary op)
      return self:toResultType(ast.op, false, childType)
    end
  elseif ast.tag == 'ternary' then
    local testType = self:checkExpression(ast.test)
    if not self:typeMatches(testType, kBooleanType) then
      self:addError('ERROR TYPECHECK TERNARY CONDITION MUST BE BOOLEAN',
                    {testType=common.toReadableType(testType)}, ast.testPosition)
    end

    local trueBranchType = self:checkExpression(ast.trueExpression)
    local falseBranchType = self:checkExpression(ast.falseExpression)
    if not self:typeMatches(trueBranchType, falseBranchType) then
      self:addError('ERROR TYPECHECK TERNARY BRANCHES TYPE MISMATCH',
                    {trueBranchType=common.toReadableType(trueBranchType),
                     falseBranchType=common.toReadableType(falseBranchType)}, ast)
    end

    -- Assume true branch type.
    return trueBranchType
  else
    self:addError('ERROR TYPECHECK INTERNAL UNKNOWN EXPRESSION NODE TAG', {tag=ast.tag}, ast)
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
      self:addError('ERROR TYPECHECK INTERNAL UNKNOWN SCOPE WHILE INFERRING', {scope=tostring(ast.scope)}, ast)
    else
      self:addError('ERROR TYPECHECK INTERNAL UNDEFINED SCOPE WHILE INFERRING', {}, ast)
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
        self:addError('ERROR TYPECHECK VARIABLE INIT TYPE MISMATCH',
                      {specifiedType=common.toReadableType(specifiedType),
                       assignmentType=common.toReadableType(assignmentType)}, ast.type_)
      end
    elseif not ast.assignment then
      -- Functions without default values are currently disallowed.
      self:addError('ERROR TYPECHECK FUNCTION TYPE NO DEFAULT VALUE', {variableName=ast.name}, ast)
    end
  -- We aren't inferring, but invalid type specified:
  elseif not specifiedType.tag == 'infer' and not self:typeValid(specifiedType) then
    self:addError('ERROR TYPECHECK INVALID TYPE SPECIFIED',
                  {variableName=ast.name, specifiedType=common.toReadableType(specifiedType)}, ast)
  -- No type specified:
  elseif specifiedType.tag == 'infer' then
    -- Assignment?
    if ast.assignment then
      -- Set the type to the assignment value.
      inferredType = self:checkExpression(ast.assignment)
      if not self:typeValid(inferredType) then
        self:addError('ERROR TYPECHECK CANNOT INFER TYPE', {variableName=ast.name}, ast)
      end
    -- No assignment?
    else
      -- This is not currently allowed.
      self:addError('ERROR TYPECHECK CANNOT INFER TYPE NO ASSIGNMENT', {variableName=ast.name}, ast)
    end

  -- Type specified and assignment.
  elseif ast.assignment then
    -- MUST MATCH.
    local assignmentType = self:checkExpression(ast.assignment)
    if not self:typeMatches(specifiedType, assignmentType) then
      self:addError('ERROR TYPECHECK VARIABLE INIT TYPE MISMATCH',
                    {specifiedType=common.toReadableType(specifiedType),
                     assignmentType=common.toReadableType(assignmentType)}, ast.type_)
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
      self:addError('ERROR TYPECHECK FUNCTION NAME STARTS WITH CONDITIONAL',
                    {variableName=ast.name, keyword=ast.name:match('^(.*) '),
                     type=common.toReadableType(inferredType)}, ast)
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
      self:addError('ERROR TYPECHECK INTERNAL UNKNOWN SCOPE POST INFER',
                    {scope=tostring(scope), variableName=ast.name}, ast)
    else
      self:addError('ERROR TYPECHECK INTERNAL UNDEFINED SCOPE POST INFER',
                    {variableName=ast.name}, ast)
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
        self:addError('ERROR TYPECHECK RETURN TYPE UNDETERMINABLE', {}, ast)
      -- Allow none: true
      elseif not self:typeMatches(returnType, self.currentFunction.resultType, true) then
        self:addError('ERROR TYPECHECK RETURN TYPE MISMATCH',
                      {functionName=self.currentFunction.name,
                       expectedType=common.toReadableType(self.currentFunction.resultType),
                       actualType=common.toReadableType(returnType)}, ast)
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
          if etRootName then
            self:addError('ERROR TYPECHECK CANNOT ASSIGN FROM SOURCE WITH INVALID TYPE TO TARGET WITH INVALID TYPE',
                          {expressionRootName=etRootName, expressionType=common.toReadableType(expressionType),
                           targetRootName=targetRootName, targetType=common.toReadableType(targetType)}, ast.target)
          else
            self:addError('ERROR TYPECHECK CANNOT ASSIGN FROM EXPRESSION WITH INVALID TYPE TO TARGET WITH INVALID TYPE',
                          {expressionType=common.toReadableType(expressionType),
                           targetRootName=targetRootName, targetType=common.toReadableType(targetType)}, ast.target)
          end
        elseif not etValid then
          if etRootName then
            self:addError('ERROR TYPECHECK CANNOT ASSIGN FROM SOURCE WITH INVALID TYPE',
                          {expressionRootName=etRootName, expressionType=common.toReadableType(expressionType)},
                          ast.expression)
          else
            self:addError('ERROR TYPECHECK CANNOT ASSIGN FROM EXPRESSION WITH INVALID TYPE',
                          {expressionType=common.toReadableType(expressionType)}, ast.expression)
          end
        elseif not wttValid then
          self:addError('ERROR TYPECHECK CANNOT ASSIGN TO TARGET WITH INVALID TYPE',
                        {targetRootName= targetRootName, targetType=common.toReadableType(targetType)}, ast.target)
        elseif wttValid and etValid then
          self:addError('ERROR TYPECHECK ASSIGNMENT MISMATCHED TYPES',
                        {fromType=common.toReadableType(expressionType), toType=common.toReadableType(targetType)},
                        ast.target)
        end
      end
    end
  elseif ast.tag == 'if' then
    local expressionType = self:checkExpression(ast.expression)

    if not self:typeMatches(expressionType, kBooleanType) then
      self:addError('ERROR TYPECHECK IF CONDITION NOT BOOLEAN', {type=common.toReadableType(expressionType)}, ast)
    end
    self:checkStatement(ast.body)
    if ast.elseBody then
      self:checkStatement(ast.elseBody)
    end
  elseif ast.tag == 'while' then
    local expressionType = self:checkExpression(ast.expression)
    if not self:typeMatches(expressionType, kBooleanType) then
      self:addError('ERROR TYPECHECK WHILE CONDITION NOT BOOLEAN', {type=common.toReadableType(expressionType)}, ast)
    end
    self:checkStatement(ast.body)
  elseif ast.tag == 'print' then
    self:checkExpression(ast.toPrint)
  elseif ast.tag == 'exit' then
    if not self:typeMatches(kNoType, self.currentFunction.resultType, true) then
      self:addError('ERROR TYPECHECK EXIT NO RETURN', {type=common.toReadableType(self.currentFunction.resultType)})
    end
  else
    self:addError('ERROR TYPECHECK INTERNAL UNKNOWN STATEMENT NODE', {tag=ast.tag}, ast)
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
        self:addError('ERROR TYPECHECK INVALID TOP LEVEL SCOPE', {}, ast[i])
        scope = 'global'
      end

      local name = ast[i].name
      local resultType = type_.resultType
      if self.variableTypes[name] == nil then
        self.variableTypes[name] = type_
      -- Error for a function being defined with two types. Errors in other parts of the compiler for duplicate function names...
      -- TODO: Overloading support, etc. No checks on function parameters and so on...
      elseif not self:typeMatches(self.variableTypes[name].resultType, resultType) then
        self:addError('ERROR TYPECHECK FUNCTION REDEFINED',
                      {name=name, newType=common.toReadableType(resultType),
                       oldType=common.toReadableType(self.variableTypes[name].resultType)})
      end

      -- Check type of default argument expression against last parameter
      if type_.defaultArgument then
        -- No last parameter? This is also an error.
        local defaultArgumentType = self:checkExpression(type_.defaultArgument)
        local numParameters = #type_.parameters
        if numParameters == 0 then
          self:addError('ERROR TYPECHECK FUNCTION DEFAULT ARG NO PARAMS', {name=name}, ast[i])
        else
          local lastParameter = type_.parameters[numParameters]
          local parameterType = lastParameter.type_
          if not self:typeMatches(defaultArgumentType,parameterType) then
            self:addError('ERROR TYPECHECK FUNCTION DEFAULT ARG TYPE MISMATCH',
                          {name=name, defaultArgType=common.toReadableType(defaultArgumentType),
                           parameterName=lastParameter.name,
                           parameterType=common.toReadableType(parameterType)}, lastParameter)
          end
        end
      end
    end
  end

  -- Make sure entry point returns a number.
  local entryPoint = self.variableTypes[literals.entryPointName]
  if entryPoint then
    if not self:typeMatches(entryPoint.resultType, kNumberType) then
      self:addError('ERROR TYPECHECK ENTRY POINT MUST RETURN NUMBER', entryPoint.returnType)
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