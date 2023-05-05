local lpeg = require 'lpeg'
local common = require 'common'
local endToken = common.endToken
local numeral = require 'numeral'
local identifierPattern = require 'identifier'

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

local nodeVariable = node('variable', 'position', 'value')
local nodeAssignment = node('assignment', 'writeTarget', 'position', 'assignment')
local nodePrint = node('print', 'position', 'toPrint')
local nodeReturn = node('return', 'position', 'sentence')
local nodeNumeral = node('number', 'position', 'value')
local nodeIf = node('if', 'position', 'expression', 'body', 'elseBody')
local nodeWhile = node('while', 'position', 'expression', 'body')
local nodeBoolean = node('boolean', 'value')
local nodeFunction = node('function', 'position', 'name', 'body')
local nodeFunctionCall = node('functionCall', 'name')
local nodeBlock = node('block', 'body')

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

local function foldNewArray(list, initialValue)
  local tree = initialValue
  -- Reverse order, so that the leaf nodes are first in the AST.
  -- This means that `new [base][leaf] true` will write code for initialValue, newArray leaf, then newArray root,
  -- with each getting the subsequent one as a default value for all elements.
  for i = #list,1 , -2 do
    tree = { tag = 'newArray', initialValue = tree, position = list[i - 1], size = list[i] }
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
local functionCall = V'functionCall'
local boolean = V'boolean'
local variable = V'variable'
local identifier = V'identifier'
local functionDeclaration = V'functionDeclaration'
-- Something that can be written to, i.e. assigned to. AKA 'left-hand side'
local writeTarget = V'writeTarget'

local Ct, Cc, Cp = lpeg.Ct, lpeg.Cc, lpeg.Cp
local grammar =
{
'program',
program = endToken * Ct(functionDeclaration^1) * -1,

functionDeclaration = KW'function' * Cp() * identifier * delim.openFunctionParameterList * delim.closeFunctionParameterList * blockStatement / nodeFunction,

statementList = statement^-1 * (sep.statement * statementList)^-1 / nodeStatementSequence,

blockStatement = delim.openBlock * statementList * sep.statement^-1 * delim.closeBlock / nodeBlock,

elses = (KW'elseif' * Cp() * expression * blockStatement) * elses / nodeIf + (KW'else' * blockStatement)^-1,

variable = Cp() * identifier / nodeVariable,
writeTarget = Ct(variable * (delim.openArray * Cp() * expression * delim.closeArray)^0) / foldArrayElement,
functionCall = identifier * delim.openFunctionParameterList * delim.closeFunctionParameterList / nodeFunctionCall,

statement = blockStatement +
            -- Assignment - must be first to allow variables that contain keywords as prefixes.
            writeTarget * Cp() * op.assign * expression * -delim.openBlock / nodeAssignment +
            -- If
            KW'if' * Cp() * expression * blockStatement * elses / nodeIf +
            -- Return
            KW'return' * Cp() * expression / nodeReturn +
            -- While
            KW'while' * Cp() * expression * blockStatement / nodeWhile +
            -- Have to put these here or function calls may not be made in if, return, or while statements...
            functionCall +
            -- Print
            op.print * Cp() * expression / nodePrint,

boolean = (KW'true' * Cc(true) + KW'false' * Cc(false)) / nodeBoolean,

          -- Identifiers and numbers
primary = KW'new' * Ct((delim.openArray * Cp() * expression * delim.closeArray)^1) * primary / foldNewArray +
          -- Function call must be before writeTarget,
          -- or the function call's identifier will be read as a writeTarget variable,
          -- and we'll get a syntax error about the open parenthesis.
          functionCall +
          writeTarget +
          Cp() * numeral / nodeNumeral +
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

-- Avoid duplication of complicated patterns that are used more than once by defining them here
endToken = common.endTokenPattern,
identifier = identifierPattern,
}

local module = {}

function module.parse(input, pegdebug)
  local grammar = grammar
  if pegdebug then
    grammar = require('External.pegdebug').trace(grammar)
  end
  grammar = lpeg.P(grammar)
  common.clearFurthestMatch()
  local ast = grammar:match(input)

  if ast then
    ast.version = 4
    return ast
  else
    -- backup = true (if the error is at the beginning of a line, back up to the previous line)
    return ast, common.generateErrorMessage(input, common.getFurthestMatch(), true, 'at line ', 'after line ')
  end
end

return module
