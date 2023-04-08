local lpeg = require 'lpeg'
local P, C = lpeg.P, lpeg.C
local ws = require('common').ws

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
module.delim.openFactor = '(' * ws
module.delim.closeFactor = ')' * ws
module.delim.openBlock = '{' * ws
module.delim.closeBlock = '}' * ws

-- Separators
module.sep.statement = ';' * ws

module.keyword.return_ = 'return' * ws

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

module.op.assign = assign * ws
module.op.sum = C(P(add) + subtract) * ws
module.op.term = C(P(multiply) + divide + modulus) * ws
module.op.exponent = C(exponent) * ws
module.op.comparison = (C(greaterOrEqual) + C(greater) + C(lessOrEqual) + C(less) + C(equal) + C(notEqual)) * ws
module.op.unarySign = C(P(add) + subtract) * ws
module.op.print = print * ws

return module