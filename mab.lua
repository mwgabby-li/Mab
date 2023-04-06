local interpreter = require 'interpreter'
local toStackVM = require 'translators.stackVM'

local lpeg = require 'lpeg'
local pt = require 'External.pt'
local common = require 'common'
local ws = common.ws
local numeral = require 'numeral'
local identifier = require 'identifier'

local symbols = require 'symbols'
local op = symbols.op
local keyword = symbols.keyword
local sep = symbols.sep
local delim = symbols.delim

---- AST ---------------------------------------------------------------------------------------------------------------
local function nodeVariable(variable)
  return {tag = 'variable', value = variable}
end

local function nodeAssignment(identifier, assignment)
  return {tag = 'assignment', identifier = identifier, assignment = assignment}
end

local function nodePrint(toPrint)
    return { tag='print', toPrint=toPrint }
end

local function nodeReturn(sentence)
    return { tag='return', sentence = sentence }
end

local function nodeNumeral(num)
    return {tag = 'number', value = num}
end

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

local function unaryMinusToMultiply(sign, factor)
  if sign == '-' then
    return { tag='binaryOp', op = '*', firstChild = { tag="number", value=-1 }, secondChild = factor }
  else
    return factor
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
local basicFactor, exponentExpr, termExpr = V'basicFactor', V'exponentExpr', V'termExpr'
local sumExpr, comparisonExpr, unaryExpr = V'sumExpr', V'comparisonExpr', V'unaryExpr'
local statement, statementList = V'statement', V'statementList'
local blockStatement = V'blockStatement'

local Ct = lpeg.Ct
local grammar = lpeg.P
{
'statementList',

statementList = statement^-1 * (sep.statement * statementList)^-1 / nodeStatementSequence,

blockStatement = delim.openBlock * statementList * sep.statement^-1 * delim.closeBlock,

statement = blockStatement +
            -- Assignment
            identifier * op.assign * comparisonExpr / nodeAssignment +
            -- Return
            keyword.return_ * comparisonExpr / nodeReturn +
            -- Print
            op.print * comparisonExpr / nodePrint,

              -- Identifiers and numbers
basicFactor = numeral / nodeNumeral + identifier / nodeVariable +
              -- Sentences in the language enclosed in parentheses
              delim.openFactor * comparisonExpr * delim.closeFactor,

-- From highest to lowest precedence
unaryExpr = basicFactor + op.unarySign * basicFactor / unaryMinusToMultiply,
exponentExpr = Ct(unaryExpr * (op.exponent * unaryExpr)^0) / foldBinaryOps,
termExpr = Ct(exponentExpr * (op.term * exponentExpr)^0) / foldBinaryOps,
sumExpr = Ct(termExpr * (op.sum * termExpr)^0) / foldBinaryOps,
comparisonExpr = Ct(sumExpr * (op.comparison * sumExpr)^0) / foldBinaryOps,
}
grammar = ws * grammar * -1

local function parse(input)
  return grammar:match(input)
end

if arg[1] ~= nil and (string.lower(arg[1]) == '--tests' or string.lower(arg[1]) == '-t') then
  arg[1] = nil
  local lu = require 'External.luaunit'
  testFrontend = require 'tests':init(parse, toStackVM, interpreter)
  testNumerals = require 'numeral.tests'
  testIdentifiers = require 'identifier.tests'

  os.exit(lu.LuaUnit.run())
end

local show = {}
for _, argument in ipairs(arg) do
  if argument:lower() == '--tests' then
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
  end
end

common.poem()
print ''

--local input = io.read()
local input = 'x = 1; x = x + 2;; @x'
if show.input then
  print 'Input:'
  print(input)
end
io.write 'Parsing...'
local start = os.clock()
local ast = parse(input)
print(string.format('     complete: %0.2f milliseconds.', (os.clock() - start) * 1000))
io.write 'Translating...'
start = os.clock()
local code = toStackVM.translate(ast)
print(string.format(' complete: %0.2f milliseconds.', (os.clock() - start) * 1000))

print 'Executing...'
start = os.clock()
local trace = {}
if not show.trace then
  trace = nil
end
local result = interpreter.run(code, trace)
print(string.format('     Execution complete: %0.2f milliseconds.', (os.clock() - start) * 1000))

if show.AST then
  print '\nAST:'
  print(pt.pt(ast))
end
if show.code then
  print '\nGenerated code:'
  print(pt.pt(code))
end
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