local lpeg = require 'lpeg'
local tokens = require 'tokens'

-- Patterns
local P, R, S = lpeg.P, lpeg.R, lpeg.S
local Cmt = lpeg.Cmt

local endToken = require('common').endToken

local alpha = R('AZ', 'az')
local identifierStartCharacters = (alpha + '_')
local digit = R'09'
local identifierTailCharacters = (alpha + digit + '_')

local function getIdentifier(subject, position, match)
  
  if tokens.kw[match] then
    return false
  else
    return true, match
  end
end

return Cmt(identifierStartCharacters *(S' -'^-1 * identifierTailCharacters)^0, getIdentifier)* endToken
