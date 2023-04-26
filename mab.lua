#!/usr/bin/env lua

local typeChecker = require 'typechecker'
local toStackVM = require 'translators.stackVM'
local graphviz = require 'translators.graphviz'
local interpreter = require 'interpreter'

local lpeg = require 'lpeg'
local pt = require 'External.pt'
local common = require 'common'
local endToken = common.endToken
local numeral = require 'numeral'
local identifier = require 'identifier'

local tokens = require 'tokens'
local op = tokens.op
local KW = tokens.KW
local sep = tokens.sep
local delim = tokens.delim
local I = common.I

---- AST ---------------------------------------------------------------------------------------------------------------

local function node(tag, ...)
  local labels = {...}
  local parameters = table.concat(labels, ', ')
  local fields = string.gsub(parameters, '(%w+)', '%1 = %1')
  local code = string.format(
    'return function(%s) return {tag = "%s", %s} end',
    parameters, tag, fields)
    return assert(load(code))()
end

--local function node(tag, ...)
--  local labels = {...}
--  return function(...)
--    local parameters = {...}
--    local result = {tag = tag}
--    for ordex, value in pairs(labels) do
--      result[value] = parameters[ordex]
--    end
--    return result
--  end
--end

local nodeVariable = node('variable', 'value')
local nodeAssignment = node('assignment', 'writeTarget', 'position', 'assignment')
local nodePrint = node('print', 'position', 'toPrint')
local nodeReturn = node('return', 'position', 'sentence')
local nodeNumeral = node('number', 'value')
local nodeIf = node('if', 'position', 'expression', 'block', 'elseBlock')
local nodeWhile = node('while', 'position', 'expression', 'block')
local nodeBoolean = node('boolean', 'value')
local nodeNewArray = node('newArray', 'sizes', 'initialValueExpression')

local function nodeStatementSequence(first, rest)
  -- When first is empty, rest is nil, so we return an empty statement.
  -- This can happen if there is a sequence of statement separators at the end, e.g. "1;2;;",
  -- if there are no statements at all, e.g. "", or if there are ONLY statement separators, e.g. ";;".
  if first == '' then
    return { tag = 'emptyStatement' }
  -- If first is NOT empty, but rest is nil or empty, we can prune rest and just return first.
  elseif rest == nil or rest.tag == 'emptyStatement' then
    return first
  -- If first is an empty statement, but rest isn't, we can prune the empty statement and return rest.
  elseif first.tag == 'emptyStatement' then
    return rest
  -- Otherwise, both first and rest are non-empty statements, so we need to return a statement sequence.
  else
    return { tag='statementSequence', firstChild = first, secondChild = rest }
  end
end

local function addUnaryOp(operator, position, expression)
  return { tag = 'unaryOp', op = operator, position=position, child = expression }
end

local function addExponentOp(expression1, position, op, expression2)
  if op then
    return { tag = 'binaryOp', firstChild = expression1, position = position, op = op, secondChild = expression2 }
  else
    return expression1
  end
end


local function foldBinaryOps(list)
  local tree = list[1]
  for i = 2, #list, 3 do
    tree = { tag = 'binaryOp', firstChild = tree, position = list[i], op = list[i + 1], secondChild = list[i + 2] }
  end
  return tree
end

local function foldArrayElement(list)
  local tree = list[1]
  for i = 2, #list, 2 do
    tree = { tag = 'arrayElement', array = tree, position = list[i], index = list[i + 1] }
  end
  return tree
end

---- Grammar -----------------------------------------------------------------------------------------------------------
local V = lpeg.V
local primary, exponentExpr, termExpr = V'primary', V'exponentExpr', V'termExpr'
local sumExpr, comparisonExpr, unaryExpr, logicExpr = V'sumExpr', V'comparisonExpr', V'unaryExpr', V'logicExpr'
local notExpr = V'notExpr'
local statement, statementList = V'statement', V'statementList'
local elses = V'elses'
local blockStatement = V'blockStatement'
local expression = V'expression'
local boolean = V'boolean'
local variable = V'variable'
-- Something that can be written to, i.e. assigned to. AKA 'left-hand side'
local writeTarget = V'writeTarget'

local Ct, Cc, Cp = lpeg.Ct, lpeg.Cc, lpeg.Cp
local grammar =
{
'program',
program = endToken * statementList * -1,

statementList = statement^-1 * (sep.statement * statementList)^-1 / nodeStatementSequence,

blockStatement = delim.openBlock * statementList * sep.statement^-1 * delim.closeBlock,

elses = (KW'elseif' * Cp() * expression * blockStatement) * elses / nodeIf + (KW'else' * blockStatement)^-1,

variable = identifier / nodeVariable,
writeTarget = Ct(variable * (delim.openArray * Cp() * expression * delim.closeArray)^0) / foldArrayElement,

statement = blockStatement +
            -- Assignment - must be first to allow variables that contain keywords as prefixes.
            writeTarget * op.assign * Cp() * expression * -delim.openBlock / nodeAssignment +
            -- If
            KW'if' * Cp() * expression * blockStatement * elses / nodeIf +
            -- Return
            KW'return' * Cp() * expression / nodeReturn +
            -- While
            KW'while' * Cp() * expression * blockStatement / nodeWhile +
            -- Print
            op.print * Cp() * expression / nodePrint,

boolean = (KW'true' * Cc(true) + KW'false' * Cc(false)) / nodeBoolean,

          -- Identifiers and numbers
primary = Ct(KW'new' * (delim.openArray * expression * delim.closeArray)^1) * primary / nodeNewArray +
          writeTarget +
          numeral / nodeNumeral +
          -- Literal booleans
          boolean +
          -- Sentences in the language enclosed in parentheses
          delim.openFactor * expression * delim.closeFactor,

-- From highest to lowest precedence
exponentExpr = primary * (Cp() * op.exponent * exponentExpr)^-1 / addExponentOp,
unaryExpr = op.unarySign * Cp() * unaryExpr / addUnaryOp + exponentExpr,
termExpr = Ct(unaryExpr * (Cp() * op.term * unaryExpr)^0) / foldBinaryOps,
sumExpr = Ct(termExpr * (Cp() * op.sum * termExpr)^0) / foldBinaryOps,
notExpr = op.not_ * Cp() * notExpr / addUnaryOp + sumExpr,
comparisonExpr = Ct(notExpr * (Cp() * op.comparison * notExpr)^0) / foldBinaryOps,
logicExpr = Ct(comparisonExpr * (Cp() * op.logical * comparisonExpr)^0) / foldBinaryOps,
expression = logicExpr,

endToken = common.endTokenPattern,
}

local function parse(input)
  common.clearFurthestMatch()
  local ast = grammar:match(input)
  
  if ast then
    return ast
  else    
    -- backup = true (if the error is at the beginning of a line, back up to the previous line)
    return ast, common.generateErrorMessage(input, common.getFurthestMatch(), true)
  end
end

if arg[1] ~= nil and (string.lower(arg[1]) == '--tests') then
  common.poem(true)
  arg[1] = nil
  local lu = require 'External.luaunit'
  testFrontend = require 'tests':init(parse, typeChecker, toStackVM, interpreter)
  testNumerals = require 'numeral.tests'
  testIdentifiers = require 'identifier.tests'

  -- Close the grammar (it's just a table at this point)
  grammar = lpeg.P(grammar)

  os.exit(lu.LuaUnit.run())
end

local show = {}
local input_file
local awaiting_filename = false
for index, argument in ipairs(arg) do
  if awaiting_filename then
    local status, err = pcall(io.input, arg[index])
    input_file = arg[index]
    if not status then
      print('Could not open file "' .. arg[index] .. '"\n\tError: ' .. err)
      os.exit(1)
    end
    awaiting_filename = false
  elseif argument:lower() == '--input' or argument:lower() == '-i' then
    awaiting_filename = true
  elseif argument:lower() == '--tests' then
    print('-tests must be the first argument if it is being sent in.')
    os.exit(1)
  elseif argument:lower() == '--ast' or argument:lower() == '-a' then
    show.AST = true
  elseif argument:lower() == '--code' or argument:lower() == '-c' then
    show.code = true
  elseif argument:lower() == '--trace' or argument:lower() == '-t' then
    show.trace = true
  elseif argument:lower() == '--result' or argument:lower() == '-r' then
    show.result = true
  elseif argument:lower() == '--echo-input' or argument:lower() == '-e' then
    show.input = true
  elseif argument:lower() == '--graphviz' or argument:lower() == '-g' then
    show.graphviz = true
  elseif argument:lower() == '--pegdebug' or argument:lower() == '-p' then
    show.pegdebug = true
  else
    print('Unknown argument ' .. argument .. '.')
    os.exit(1)
  end
end

if awaiting_filename then
  print 'Specified -i, but no input file found.'
  os.exit(1)
end

common.poem() print ''

-- Need to keep the grammar open up to here so that PegDebug can annotate it if that setting's on.
if show.pegdebug then
  grammar = require('External.pegdebug').trace(grammar)
end
grammar = lpeg.P(grammar)

local input = io.read 'a'
if show.input then
  print 'Input:'
  print(input)
end
io.write 'Parsing...'
local start = os.clock()
local ast, errorMessage = parse(input)
print(string.format('         %s: %0.2f milliseconds.', ast and 'complete' or '  FAILED', (os.clock() - start) * 1000))

if errorMessage then
  io.stderr:write('Failed to generate AST from input. Unable to continue ' .. errorMessage)
  return 1
end

if show.graphviz then
  local prefix = input_file or 'temp'
  local dotFileName = prefix .. '.dot'
  local dotFile = io.open(dotFileName, 'wb')
  dotFile:write(graphviz.translate(ast))
  dotFile:close()
  local svgFileName = prefix .. '.svg'
  os.execute('dot ' .. '"' .. dotFileName .. '" -Tsvg -o "' .. svgFileName .. '"')
  os.execute('firefox "'.. svgFileName .. '" &')
end

if show.AST then
  print '\nAST:'
  print(pt.pt(ast, {'tag', 'identifier', 'assignment', 'value', 'firstChild', 'op', 'child', 'secondChild'}))
end

io.write '\nType checking...'
start = os.clock()
local errors = typeChecker.check(ast)
print(string.format('   %s: %0.2f milliseconds.', (#errors == 0) and 'complete' or '  FAILED', (os.clock() - start) * 1000))
if #errors > 0 then
  print('\nType checking failed:')
  local sortedErrors = {}
  for _, errorTable in ipairs(errors) do
    -- backup = false (positions for type errors are precise)
    io.write(errorTable.message .. ' ')
    if errorTable.position then
      io.write(common.generateErrorMessage(input, errorTable.position, false))
    end
    io.write'\n'
  end
  
  return 1
end

io.write '\nTranslating...'
start = os.clock()
local code = toStackVM.translate(ast)
print(string.format('     %s: %0.2f milliseconds.', code and 'complete' or '  FAILED', (os.clock() - start) * 1000))

if code == nil then
  print '\nFailed generate code from input:'
  print(input)
  print '\nAST:'
  print(pt.pt(ast, {'tag', 'identifier', 'assignment', 'value', 'firstChild', 'op', 'child', 'secondChild'}))
  return 1
end

if show.code then
  print '\nGenerated code:'
  print(pt.pt(code))
end

print '\nExecuting...'
start = os.clock()
local trace = {}
if not show.trace then
  trace = nil
end
local result = interpreter.run(code, trace)
print(string.format('         Execution %s: %0.2f milliseconds.', result ~= nil and 'complete' or '  FAILED', (os.clock() - start) * 1000))

if show.trace then
  print '\nExecution trace:'
  for k, v in ipairs(trace) do
    print(k, v)
  end
end
if show.result then
  print '\nResult:'
  print(result)
end