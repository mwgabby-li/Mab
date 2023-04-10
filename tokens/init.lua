local lpeg = require 'lpeg'
local P, C = lpeg.P, lpeg.C
local l = require 'literals'
local endToken = require('common').endToken

local module = { op = {}, delim = {}, sep = {}, kw = {}  }

-- Delimiters
module.delim.openFactor = l.delim.openFactor * endToken
module.delim.closeFactor = l.delim.closeFactor * endToken
module.delim.openBlock = l.delim.openBlock * endToken
module.delim.closeBlock = l.delim.closeBlock * endToken

-- Separators
module.sep.statement = l.sep.statement * endToken

module.kw.return_ = l.kw.return_ * endToken

module.op.assign = l.op.assign * endToken
module.op.sum = C(P(l.op.add) + l.op.subtract) * endToken
module.op.term = C(P(l.op.multiply) + l.op.divide + l.op.modulus) * endToken
module.op.exponent = C(l.op.exponent) * endToken
module.op.comparison = (C(l.op.greaterOrEqual) + C(l.op.greater) +
                        C(l.op.lessOrEqual) + C(l.op.less) +
                        C(l.op.equal) + C(l.op.notEqual)) * endToken
module.op.unarySign = C(P(l.op.add) + l.op.subtract) * endToken
module.op.print = l.op.print * endToken

return module
