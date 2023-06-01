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

  -- Can't start with keywords.
  if match:find '^do ' or match:find '^end ' or match:find '^then ' then
    return false
  end

  -- Can't end with keywords. Cut them off!
  --  It's important to do this before checking anything else.
  local cut = 0
  if match:find ' do$' then
    cut = 3
  end
  if match:find ' end$' then
    cut = 4
  end
  if match:find ' then$' then
    cut = 5
  end

  match = match:sub(1, #match - cut)

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
