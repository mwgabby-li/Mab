local lpeg = require 'lpeg'
local P, C = lpeg.P, lpeg.C
local endToken = require('common').endToken

local module = { op = {}, delim = {}, sep = {}, keyword = {}  }

-- Language special characters, they can be customized here.
local assign = '='
local add = '+'
local subtract = '-'
local multiply = '*'
local divide = '/'
local modulus = '%'
local exponent = '^'
local less = '<'
local greater = '>'
local lessOrEqual = '<='
local greaterOrEqual = '>='
local equal = '=='
local notEqual = '~='
local print = '@'

-- Delimiters
module.delim.openFactor = '(' * endToken
module.delim.closeFactor = ')' * endToken
module.delim.openBlock = '{' * endToken
module.delim.closeBlock = '}' * endToken

-- Separators
module.sep.statement = ';' * endToken

module.keyword.return_ = 'return' * endToken

module.op.toName = {
  [add] = 'add',
  [subtract] = 'subtract',
  [multiply] = 'multiply',
  [divide] = 'divide',
  [modulus] = 'modulus',
  [exponent] = 'exponent',
  [less] = 'less',
  [greater] = 'greater',
  [lessOrEqual] = 'lessOrEqual',
  [greaterOrEqual] = 'greaterOrEqual',
  [equal] = 'equal',
  [notEqual] = 'notEqual',
}

module.op.unaryToName = {
    [subtract] = 'negate',
}

module.op.assign = assign * endToken
module.op.sum = C(P(add) + subtract) * endToken
module.op.term = C(P(multiply) + divide + modulus) * endToken
module.op.exponent = C(exponent) * endToken
module.op.comparison = (C(greaterOrEqual) + C(greater) + C(lessOrEqual) + C(less) + C(equal) + C(notEqual)) * endToken
module.op.unarySign = C(P(add) + subtract) * endToken
module.op.print = print * endToken

return module