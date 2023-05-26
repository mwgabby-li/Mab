local lpeg = require 'lpeg'
local tokens = require 'tokens'

-- Patterns
local C, P, S, R = lpeg.C, lpeg.P, lpeg.S, lpeg.R
local Cmt = lpeg.Cmt

local endToken = require('common').endToken

local alpha = R('AZ', 'az')
local digit = R'09'
local identifierCharacters = (alpha + digit + '_')

local function getIdentifier(subject, position, match)
  match = C(identifierCharacters *(S' -'^-1 * identifierCharacters)^0):match(subject:sub(position, #subject))
  if not match then
    return false
  end

  -- Identifiers may not end with a base indicator.
  if match:find('b[0-9]+$') then
    return false
  end

  -- Identifiers must contain at least one letter.
  if not match:find('%a') then
    return false
  end

  -- Identifiers may not be the same as keywords.
  if tokens.kw[match] then
    return false
  else
    return position + #match, match
  end
end

return Cmt(P(true), getIdentifier)* endToken
