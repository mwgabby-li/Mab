local lpeg = require 'lpeg'


-- Patterns
local P, R = lpeg.P, lpeg.R

local ws = require('common').ws

local alpha = R('AZ', 'az')
local identifierStartCharacters = (alpha + '_') * P' '^-1
local digit = R'09'
local identifierTailCharacters = (alpha + digit + '_') * P' '^-1

local function removeTrailingSpace(identifier)
  if identifier:sub(#identifier, #identifier) == ' ' then
    identifier = identifier:sub(1, #identifier - 1)
  end
  return identifier
end

return (identifierStartCharacters * identifierTailCharacters^0) / removeTrailingSpace * ws
