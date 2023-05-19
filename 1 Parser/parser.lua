local lpeg = require 'lpeg'
local common = require 'common'
local endToken = common.endToken
local numeral = require 'numeral'
local identifierPattern = require 'identifier'

local tokens = require 'tokens'
local op = tokens.op
local KW, KWc = tokens.KW, tokens.KWc
local sep = tokens.sep
local delim = tokens.delim
local I = common.I

---- AST ---------------------------------------------------------------------------------------------------------------

local function node(tag, ...)
  local labels = {...}
  local parameters = table.concat(labels, ', ')
  local fields = string.gsub(parameters, '([%w_]+)', '%1 = %1')
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
local nodeNewVariable = node('newVariable', 'scope', 'type_', 'position', 'value', 'assignment')
local nodePrint = node('print', 'position', 'toPrint')
local nodeReturn = node('return', 'position', 'sentence')
local nodeNumeral = node('number', 'position', 'value')
local nodeIf = node('if', 'position', 'expression', 'body', 'elseBody')
local nodeWhile = node('while', 'position', 'expression', 'body')
local nodeBoolean = node('boolean', 'position', 'value')
local nodeFunction = node('function', 'parameters', 'defaultArgument', 'returnType', 'position', 'name', 'block')
local nodeParameter = node('parameter', 'position', 'name', 'type_')
local nodeFunctionCall = node('functionCall', 'name', 'position', 'arguments')
local nodeBlock = node('block', 'body')
local nodeTernary = node('ternary', 'testPosition', 'test', 'position', 'truePosition', 'trueExpression', 'falsePosition', 'falseExpression')

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

local function makeArrayType(dimensions, elementType)
  local typeNode = {tag='array', dimensions={}, elementType = elementType}
  for i=1,#dimensions do
    local size = dimensions[i].tag == 'number' and dimensions[i].value or 'invalid:'..dimensions[i].tag
    typeNode.dimensions[#typeNode.dimensions + 1] = size
  end
  return typeNode
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
-- Inputs specified in the function type declaration.
local parameter = V'parameter'
local parameters = V'parameters'
-- Things passed to the function when it's invoked.
local arguments = V'arguments'

local type_ = V'type_'
local booleanType = V'booleanType'
local numberType = V'numberType'
local omittedType = V'omittedType'
local arrayType = V'arrayType'
local ternaryExpr = V'ternaryExpr'

local Ct, Cc, Cp = lpeg.Ct, lpeg.Cc, lpeg.Cp
local grammar =
{
'program',
program = endToken * Ct(functionDeclaration^1) * -1,

functionDeclaration = KW'function' * parameters * ((op.assign * expression) + Cc(false)) * sep.functionResult * type_ * sep.newVariable * Cp() * identifier * blockStatement / nodeFunction,
parameter = Cp() * identifier * sep.parameter * type_ / nodeParameter,
parameters = Ct((parameter * (parameter)^0)^-1),

statementList = statement^-1 * (sep.statement * statementList)^-1 / nodeStatementSequence,

blockStatement = delim.openBlock * statementList * sep.statement^-1 * delim.closeBlock / nodeBlock,

elses = (KW'elseif' * Cp() * expression * blockStatement) * elses / nodeIf + (KW'else' * blockStatement)^-1,

variable = Cp() * identifier / nodeVariable,
writeTarget = Ct(variable * (delim.openArray * Cp() * expression * delim.closeArray)^0) / foldArrayElement,
functionCall = identifier * Cp() * delim.openFunctionParameterList * arguments * delim.closeFunctionParameterList / nodeFunctionCall,
arguments = Ct((expression * (sep.argument * expression)^0)^-1),

statement = blockStatement +
            -- Assignment - must be first to allow variables that contain keywords as prefixes.
            writeTarget * Cp() * op.assign * expression * -delim.openBlock / nodeAssignment +
            -- New variable
            (KWc'global' + KWc'local' + Cc'local') * type_ * sep.newVariable * Cp() * identifier * (op.assign * expression)^-1 / nodeNewVariable +
            -- If
            KW'if' * Cp() * expression * blockStatement * elses / nodeIf +
            -- Return
            KW'return' * Cp() * expression / nodeReturn +
            -- While
            KW'while' * Cp() * expression * blockStatement / nodeWhile +
            -- Call keyword is a solution for functions as statements and whitespace in identifiers,
            -- while retaining the ability of identifiers to start with keywords.
            KW'call' * functionCall +
            -- Print
            op.print * Cp() * expression / nodePrint,

booleanType = Cp() * KW'boolean' / node('boolean', 'position'),
numberType = Cp() * KW'number' / node('number', 'position'),
omittedType = Cp() / node('unknown', 'position'),
arrayType = Ct((delim.openArray * expression * delim.closeArray)^1) * (booleanType + numberType + omittedType) / makeArrayType,


type_ = (booleanType + numberType + arrayType + omittedType),

boolean = (Cp() * KW'true' * Cc(true) + Cp() * KW'false' * Cc(false)) / nodeBoolean,

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
ternaryExpr = Cp() * logicExpr * Cp() * op.ternary * Cp() * expression * op.ternaryBranch * Cp() * expression / nodeTernary + logicExpr,
-- Set this to the lowest one so nothing else has to change if a new one is added that's lower.
expression = ternaryExpr,

-- Avoid duplication of complicated patterns that are used more than once by defining them here
endToken = common.endTokenPattern,
identifier = identifierPattern,
}

local module = {}

local ParserErrorReporter = { position = false }

function ParserErrorReporter:addError(position)
  self.position = position
end

function ParserErrorReporter:count()
  return self.position and 1 or 0
end

function ParserErrorReporter:outputErrors(input)
  if self.position then
    io.stderr:write(common.generateErrorMessage(input, self.position, true,
                              'at line ', 'after line ')..'\n')
  end
end

function module.parse(input, parameters)
  ParserErrorReporter.position = false
  local grammar = grammar
  if parameters and parameters.pegdebug then
    grammar = require('External.pegdebug').trace(grammar)
  end
  grammar = lpeg.P(grammar)
  common.clearFurthestMatch()
  local ast = grammar:match(input)

  if ast then
    ast.version = common.parserVersionHash()
    return ParserErrorReporter, ast
  else
    ParserErrorReporter:addError(common:getFurthestMatch())
    return ParserErrorReporter, false
  end
end

return module
