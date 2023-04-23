local module = {}
local l_op = require('literals').op

local TypeChecker = {}

local typeCompatibleBinaryOps = {
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
    [l_op.and_] = true,
    [l_op.or_] = true,
  },
}

local typeCompatibleUnaryOps = {
  boolean = {
    [l_op.positive] = true,
    [l_op.not_] = true,
  },
  
  number = {
    [l_op.negate] = true,
  }
}
    
local resultTypeBinaryOps = {
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
}
local resultTypeUnaryOps = {
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

function TypeChecker:addVariable(identifier, typeOfIdentifier)
  -- To-Do: Scope?
  self.variableTypes[identifier] = typeOfIdentifier
end

function TypeChecker:checkExpression(ast)
  if ast.tag == 'number' then
    return 'number'
  elseif ast.tag == 'boolean' then
    return 'boolean'
  elseif ast.tag == 'variable' then
    return self.variableTypes[ast.value]
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

    if firstChildType ~= secondChildType then
      self:addError('Mismatched types with operator "' .. ast.op ..
                    '"! (' .. firstChildType .. ' ' .. ast.op ..
                    ' ' .. secondChildType .. ')', ast)
      return nil
    end
    local expressionType = firstChildType
    if not typeCompatibleBinaryOps[expressionType][ast.op] then
      self:addError('Operator "' .. ast.op .. '" cannot be used with type "' .. expressionType .. '"!', ast)
      return nil
    else
      return resultTypeBinaryOps[expressionType][ast.op]
    end
  elseif ast.tag == 'unaryOp' then
    local childType = self:checkExpression(ast.child)

    if not typeCompatibleUnaryOps[childType][ast.op] then
      self:addError('Operator "' .. ast.op .. '" cannot be used with type "' .. firstChildType .. '"!', ast)
      return nil
    else
      return resultTypeUnaryOps[childType][ast.op]
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
    local expressionType = self:checkExpression(ast.assignment)
    local variablesCurrentType = self.variableTypes[ast.identifier]
    if variablesCurrentType ~= nil and variablesCurrentType ~= expressionType then
      self:addError('Attempted to change type of variable "'.. ast.identifier ..'" from "' ..
                    variablesCurrentType .. '" to "' .. expressionType.. '. Disallowed, sorry!', ast)
    -- No changing variable types for now
    else
      self:addVariable(ast.identifier, expressionType)
    end
  elseif ast.tag == 'if' then
    local expressionType = self:checkExpression(ast.expression)

    if expressionType ~= 'boolean' then
      self:addError('if statements require a boolean value or an expression evaluating to a boolean.', ast)
    end
    self:checkStatement(ast.block)
    if ast.elseBlock then
      self:checkStatement(ast.elseBlock)
    end
  elseif ast.tag == 'while' then
    local expressionType = self:checkExpression(ast.expression)
    if expressionType ~= 'boolean' then
      self:addError('while loop conditionals require a boolean value or an expression evaluating to a boolean.', ast)
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