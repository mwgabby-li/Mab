#!/usr/bin/env lua

local interpreter = require 'interpreter'
local toStackVM = require 'translators.stackVM'
local graphviz = require 'translators.graphviz'

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
local nodeAssignment = node('assignment', 'identifier', 'assignment')
local nodePrint = node('print', 'toPrint')
local nodeReturn = node('return', 'sentence')
local nodeNumeral = node('number', 'value')
local nodeIf = node('if', 'expression', 'block', 'elseBlock')

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

local function addUnaryOp(operator, expression)
  return { tag = 'unaryOp', op = operator, child = expression }
end

local function addExponentOp(expression1, op, expression2)
  if op then
    return { tag = 'binaryOp', firstChild = expression1, op = op, secondChild = expression2 }
  else
    return expression1
  end
end


local function foldBinaryOps(list)
  local tree = list[1]
  for i = 2, #list, 2 do
    tree = { tag = 'binaryOp', firstChild = tree, op = list[i], secondChild = list[i + 1] }
  end
  return tree
end

---- Grammar -----------------------------------------------------------------------------------------------------------
local V = lpeg.V
local primary, exponentExpr, termExpr = V'primary', V'exponentExpr', V'termExpr'
local sumExpr, comparisonExpr, unaryExpr = V'sumExpr', V'comparisonExpr', V'unaryExpr'
local notExpr = V'notExpr'
local statement, statementList = V'statement', V'statementList'
local blockStatement = V'blockStatement'

local Ct = lpeg.Ct
local grammar =
{
'program',
program = endToken * statementList * -1,

statementList = statement^-1 * (sep.statement * statementList)^-1 / nodeStatementSequence,

blockStatement = delim.openBlock * statementList * sep.statement^-1 * delim.closeBlock,

statement = blockStatement +
            -- Assignment - must be first to allow variables that contain keywords as prefixes.
            identifier * op.assign * comparisonExpr / nodeAssignment +
            -- If
            KW'if' * comparisonExpr * blockStatement * (KW'else' * blockStatement)^-1 / nodeIf +
            -- Return
            KW'return' * comparisonExpr / nodeReturn +
            -- Print
            op.print * comparisonExpr / nodePrint,

              -- Identifiers and numbers
primary = numeral / nodeNumeral + identifier / nodeVariable +
              -- Sentences in the language enclosed in parentheses
              delim.openFactor * comparisonExpr * delim.closeFactor,

-- From highest to lowest precedence
exponentExpr = primary * (op.exponent * exponentExpr)^-1 / addExponentOp,
unaryExpr = op.unarySign * unaryExpr / addUnaryOp + exponentExpr,
termExpr = Ct(unaryExpr * (op.term * unaryExpr)^0) / foldBinaryOps,
sumExpr = Ct(termExpr * (op.sum * termExpr)^0) / foldBinaryOps,
notExpr = op.unaryNot * notExpr / addUnaryOp + sumExpr,
comparisonExpr = Ct(notExpr * (op.comparison * notExpr)^0) / foldBinaryOps,

endToken = common.endTokenPattern,
}

local function parse(input)
  common.clearFurthestMatch()
  return grammar:match(input)
end

if arg[1] ~= nil and (string.lower(arg[1]) == '--tests') then
  common.poem(true)
  arg[1] = nil
  local lu = require 'External.luaunit'
  testFrontend = require 'tests':init(parse, toStackVM, interpreter)
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
local ast = parse(input)
print(string.format('         %s: %0.2f milliseconds.', ast and 'complete' or '  FAILED', (os.clock() - start) * 1000))

if not ast then
  local furthestMatch = common.getFurthestMatch()
  
  -- Count the number of newlines - the number of line breaks plus one is the current line
  local newlineCount = common.count('\n', input:sub(1, furthestMatch ))
  local errorLine = newlineCount + 1

  -- If the previous character was a newline, this means we (sort of) failed at the end of the line.
  -- Show the failure on the previous line, and one character back so that the caret is after the last character
  -- on that line.
  io.write '\nFailed to generate AST from input. Unable to continue '
  if input:sub(furthestMatch - 1, furthestMatch - 1) == '\n' then
    errorLine = errorLine - 1
    furthestMatch = furthestMatch - 1
    -- On \r\n systems, we need to backtrack twice since there are two characters in a line ending,
    -- so we will be at the same place visually as on \n systems.
    if input:sub(furthestMatch - 1, furthestMatch - 1) == '\r' then
      furthestMatch = furthestMatch - 1
    end
    print('after line ' .. errorLine .. ':')
  else
    print('at line ' .. errorLine .. ':')
  end

  local contextAfter = 2
  local contextBefore = 2

  local lineNumber = 1
  
  -- Keep track of the current character in the subject, since we're breaking things into lines
  local currentCharacter = 0
  -- Number of digits tells us how much padding we should add to line numbers so they line up
  local digits = math.ceil(math.log10(errorLine + contextAfter))
  local includeNewlines = true
  for line in common.lines(input, includeNewlines) do
    if lineNumber >= errorLine - contextBefore and lineNumber <= errorLine + contextAfter then
      local lineNumberPrefixed = string.format('%'..(digits)..'d',lineNumber) 
      if lineNumber == errorLine then
        local failureCharacter = furthestMatch - currentCharacter
        io.write('>' .. lineNumberPrefixed .. ' ' .. line)
        io.write(' ' .. string.rep(' ', #lineNumberPrefixed) .. string.rep(' ', failureCharacter) .. '^\n') 
      else
        io.write(' ' .. lineNumberPrefixed .. ' ' .. line)
      end
    end
    
    lineNumber = lineNumber + 1
    currentCharacter = currentCharacter + #line
  end

  return 1;
end

if show.graphviz then
  local prefix = input_file and input_file or 'temp'
  local dotFileName = prefix .. '.dot'
  local dotFile = io.open(dotFileName, 'wb')
  dotFile:write(graphviz.translate(ast))
  dotFile:close()
  local svgFileName = prefix .. '.svg'
  os.execute('dot ' .. '"' .. dotFileName .. '" -Tsvg -o "' .. svgFileName .. '"')
  os.execute('firefox "'.. svgFileName .. '"')
end

if show.AST then
  print '\nAST:'
  print(pt.pt(ast, {'tag', 'identifier', 'assignment', 'value', 'firstChild', 'op', 'child', 'secondChild'}))
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
  return 1;
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
print(string.format('         Execution %s: %0.2f milliseconds.', result and 'complete' or '  FAILED', (os.clock() - start) * 1000))

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