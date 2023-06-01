local module = {}

local lpeg = require 'lpeg'

-- Patterns
local P, R, S = lpeg.P, lpeg.R, lpeg.S
-- Captures
local  C, Cc, Cmt = lpeg.C, lpeg.Cc, lpeg.Cmt

local endToken = require('common').endToken

local decimalDigit = R'09'

local naturalNumber = decimalDigit * (P' '^-1 * decimalDigit)^0
local fraction = ('.' * (P' '^-1 * decimalDigit)^0)
local numeralExponent = P'b^' * S('+-')^-1 * decimalDigit * (P' '^-1 * decimalDigit)^0

-- It's rather important that this always include something required that's not allowed in
-- base numerals, or else it might capture part of a base numeral number.
-- Note that this doesn't deal with natural numbers, those are actually handled by the base number match.
local fractionalOrExponent = C(naturalNumber * fraction * numeralExponent^-1 +
                               naturalNumber * numeralExponent +
                               -- A fractional part (can be just a .)
                               -- followed by an optional exponent.
                               fraction * numeralExponent^-1)

local function baseNumeralToNumberForCmt(subject, position, capture)
  local number = module.baseNumeralToNumber(capture)
  if number then
    return true, number
  else
    return false
  end
end

function module.baseNumeralToNumber(capture)
  if naturalNumber:match(capture) == #capture + 1 then
    capture = capture:gsub('%s+', '')    
    return tonumber(capture)
  end
  
  -- Remove optional space separators/any captured trailing spaces.
  local numeral, base = capture:gmatch('(.*) b(.+)$')()

  if numeral == nil or base == nil then
    return false
  end
  numeral = numeral:gsub('%s+', '')
  base = base:gsub('%s+', '')
  base = tonumber(base)

  if base > 1 then
    return tonumber(numeral, base)
  elseif base == 1 then
    if #(numeral:gsub('1', '')) == 0 then
      return #numeral
    else error('invalid unary number "' .. numeral .. '"')
    end
  end
  return false
end

local baseDigit = R('09', 'az', 'AZ')
local baseNumeral = baseDigit * (P' '^-1 * baseDigit)^0


local function stripToNumber(capture)
  capture = capture:gsub('%s+', '')
  capture = capture:gsub('b%^', 'e')

  return tonumber(capture)
end

module.capture = (fractionalOrExponent / stripToNumber + Cmt(baseNumeral, baseNumeralToNumberForCmt)) * endToken

return module

