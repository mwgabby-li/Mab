local lpeg = require 'lpeg'
local tokens = require 'tokens'

-- Patterns
local P, R = lpeg.P, lpeg.R
local Cmt = lpeg.Cmt

local endToken = require('common').endToken

local alpha = R('AZ', 'az')
local identifierStartCharacters = (alpha + '_') * P' '^-1
local digit = R'09'
local identifierTailCharacters = (alpha + digit + '_') * P' '^-1

local function getIdentifier(subject, position, match)
  if match:sub(#match, #match) == ' ' then
    match = match:sub(1, #match - 1)
  end
  if tokens.kw[match] then
    return false
  else
    return true, match
  end
end

return Cmt(identifierStartCharacters * identifierTailCharacters^0, getIdentifier)* endToken
