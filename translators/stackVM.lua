local module = {}
local symbols = require 'symbols'
local op = symbols.op

local function addCode(state, opcode)
  local code = state.code
  code[#code + 1] = opcode
end

local function variableToNumber(state, variable)
  local number = state.variables[variable]
  if not number then
    number = state.numVariables + 1
    state.numVariables = number
    state.variables[variable] = number
  end
  return number
end

local function codeExpression(state, ast)
  if ast.tag == 'number' then
    addCode(state, 'push')
    addCode(state, ast.value)
  elseif ast.tag == 'variable' then
    if state.variables[ast.value] == nil then
      error('Trying to load from undefined variable "' .. ast.value .. '."')
    end
    addCode(state, 'load')
    addCode(state, variableToNumber(state, ast.value))
  elseif ast.tag == 'binaryOp' then
    codeExpression(state, ast.firstChild)
    codeExpression(state, ast.secondChild)
    addCode(state, op.toName[ast.op])
  elseif ast.tag == 'unaryOp' then
    codeExpression(state, ast.child)
    if ast.op == '-' then
      addCode(state, op.unaryToName[ast.op])
    end
  else error 'invalid tree'
  end
end

local function codeStatement(state, ast)
  if ast.tag == 'emptyStatement' then
    return
  elseif ast.tag == 'statementSequence' then
    codeStatement(state, ast.firstChild)
    codeStatement(state, ast.secondChild)
  elseif ast.tag == 'return' then
    codeExpression(state, ast.sentence)
    addCode(state, 'return')
  elseif ast.tag == 'assignment' then
    codeExpression(state, ast.assignment)
    addCode(state, 'store')
    addCode(state, variableToNumber(state, ast.identifier))
  elseif ast.tag == 'print' then
    codeExpression(state, ast.toPrint)
    addCode(state, 'print')
  else error 'invalid tree'
  end
end


function module.translate(ast)
  local state = {code = {}, variables = {}, numVariables = 0 }
  codeStatement(state, ast)
  addCode(state, 'push')
  addCode(state, 0)
  addCode(state, 'return')
  return state.code
end

return module