local lpeg = require 'lpeg'
local P, C = lpeg.P, lpeg.C
local l = require 'literals'
local endToken = require('common').endToken

local function T(tokenize)
  return tokenize * endToken
end

-- Operators, delimiters, separators, keywords, and keywords that capture the keyword.
local module = { op = {}, delim = {}, sep = {}, kw = {}, kwc = {} }

-- Returns a pattern that matches the keyword, and saves it in the keyword table.
function module.KW(keyword)
  if not module.kw[keyword] then
    module.kw[keyword] = keyword * -lpeg.locale().alnum * endToken
  end

  return module.kw[keyword]
end

-- Similar to KW, but the pattern returns a capture of the keyword.
function module.KWc(keyword)
  -- Make sure it's recorded in the kw table
  module.KW(keyword)

  if not module.kwc[keyword] then
    module.kwc[keyword] = C(keyword) * -lpeg.locale().alnum * endToken
  end
  return module.kwc[keyword]
end

-- Delimiters
for key, delim in pairs(l.delim) do
  module.delim[key] = T(delim)
end

-- Separators
for key, separator in pairs(l.sep) do
  module.sep[key] = T(separator)
end

module.op.assign = T(l.op.assign)
module.op.sum = T(C(P(l.op.add) + l.op.subtract))
module.op.term = T(C(P(l.op.multiply) + l.op.divide + l.op.modulus))
module.op.exponent = T(C(l.op.exponent))
module.op.comparison = T((C(l.op.greaterOrEqual) + C(l.op.greater) +
                        C(l.op.lessOrEqual) + C(l.op.less) +
                        C(l.op.equal) + C(l.op.notEqual)))
module.op.unarySign = T(C(P(l.op.positive) + l.op.negate))
module.op.not_ = T(C(l.op.not_))
module.op.print = T(l.op.print)
module.op.indexByOffset = T(l.op.indexByOffset)
module.op.logical = T(C(l.op.and_) + C(l.op.or_))
module.op.ternary = T(l.op.ternary)
module.op.ternaryBranch = T(l.op.ternaryBranch)
return module
