local module = {}
local literals = require 'literals'
local op = literals.op

local Translator = {
  code = {},
  variables = {},
  numVariables = 0,
}

function Translator:currentInstructionIndex()
  return #self.code
end

function Translator:addJump(opcode)
  self:addCode(opcode)
  self:addCode(0)
  -- Will return the location of the 'zero' placeholder we just inserted.
  return self:currentInstructionIndex()
end

function Translator:fixupJump(location)
  self.code[location] = self:currentInstructionIndex() - location
end

function Translator:addCode(opcode)
  self.code[#self.code + 1] = opcode
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

function Translator:codeExpression(ast)
  if ast.tag == 'number' then
    self:addCode('push')
    self:addCode(ast.value)
  elseif ast.tag == 'variable' then
    if self.variables[ast.value] == nil then
      error('Trying to load from undefined variable "' .. ast.value .. '."')
    end
    self:addCode('load')
    self:addCode(self:variableToNumber(ast.value))
  elseif ast.tag == 'binaryOp' then
    self:codeExpression(ast.firstChild)
    self:codeExpression(ast.secondChild)
    self:addCode(op.toName[ast.op])
  elseif ast.tag == 'unaryOp' then
    self:codeExpression(ast.child)
    if ast.op ~= '+' then
      self:addCode(op.unaryToName[ast.op])
    end
  else error 'invalid tree'
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
    self:codeExpression(ast.assignment)
    self:addCode('store')
    self:addCode(self:variableToNumber(ast.identifier))
  elseif ast.tag == 'if' then
    self:codeExpression(ast.expression)
    local jumpFixup = self:addJump('jumpIfZero')
    self:codeStatement(ast.block)
    self:fixupJump(jumpFixup)
  elseif ast.tag == 'print' then
    self:codeExpression(ast.toPrint)
    self:addCode('print')
  else error 'invalid tree'
  end
end

function module.translate(ast)
  Translator.code = {}
  Translator.variables = {}
  Translator.numVariables = 0
  Translator:codeStatement(ast)
  Translator:addCode('push')
  Translator:addCode(0)
  Translator:addCode('return')
  return Translator.code
end

return module