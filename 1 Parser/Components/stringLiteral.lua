local LPeg = require 'lpeg'
local common = require 'common'
local numeral = require 'numeral'
local literals = require 'literals'

local P = LPeg.P
local Cp, Cmt = LPeg.Cp, LPeg.Cmt

local function toLiteral(number)
  -- TODO
  error('Numeric literals not yet implemented')
end

local function toRepeats(character, number)
  return character:sub(1,1):rep(tonumber(number))
end

local function captureString(subject, position, capture)
  local remainder = subject:sub(position)

  local result, escape, character, number, offset
  if capture == '"' then
    character = '"'
    number = 1
    offset = 0
  else
    local numberLength = 0
    character = remainder:match '^[^%w%s]'
    if character == "'" then
      number = 2
    elseif character then
      number = 1
    else
      local numberString = remainder:match '[%w ]+'
      number = numeral.baseNumeralToNumber(numberString)
      numberLength = #numberString
      character = remainder:match '[%w%s]+(.)'
      
      -- It would be nice to support single-quoted strings.
      if not number then
        return false
      end
    end

    -- Add to the matched character count: The number (if any) and the character itself
    offset = numberLength + #character
    if number == 0 then error 'Number cannot be zero.' end

    -- Offset + 1 to one-based index
    remainder = remainder:sub(offset+1)
  end

  -- From the Lua reference manual:
  --  Any non-alphanumeric character
  --  (including all punctuation characters, even the non-magical)
  --  can be preceded by a '%' to represent itself in a pattern.
  escapedCharacter = '%'..character

  local notEscapes = '[^abfnrtv0-9a-fA-FxXsS'..escapedCharacter..']'
  escape = escapedCharacter:rep(number)
  result  = remainder:match('(.-)'..escape..notEscapes)

  -- Offset, plus the length of the result (which we've matched),
  -- plus number for the trailing characters
  offset = offset + #result + number

  -- Now that we have calculated how much of the subject we've consumed,
  -- we can modify the resulting string:
  -- Match end-of-line at the beginning of the subject,
  -- followed by spaces and tabs.
  -- This intentionally ignores strings with more than one
  -- end-of-line sequence at the beginning.
  -- (optional \r for Windows compatibility)
  local leadingSpace = result:match '^\r?\n([ \t]+)'
  if leadingSpace then
    -- Strip off leading spaces 
    result = result:gsub('\n'..leadingSpace, '\n')

    local toSub
    if result:sub(1, 1) == '\r' then
      -- \r\n, start at the third character, 
      -- the first character after the \r\n.
      toSub = 3
      -- If there are two newlines, skip past both:
      if result:sub(3,3) == '\r' then
        toSub = toSub + 2
      end
    else
      -- Only \n?
      -- Normally, skip past the \n to the start.
      toSub = 2
      -- If there are two \n, then skip past both.
      if result:sub(2,2) == '\n' then
        toSub = toSub + 1
      end
    end

    result = result:sub(toSub)
  end

  -- Do all escapes
  result = result:gsub(escape..'a', '\a')
  result = result:gsub(escape..'b', '\b')
  result = result:gsub(escape..'f', '\f')
  result = result:gsub(escape..'n', '\n')
  result = result:gsub(escape..'r', '\r')
  result = result:gsub(escape..'t', '\t')
  result = result:gsub(escape..'v', '\v')
  result = result:gsub(escape..'s', character:rep(number))
  result = result:gsub(escape..'[xX0][0-9]+', toLiteral)
  result = result:gsub('('..escape..')([1-9])', toRepeats)

  -- Ignore ending quotes that it's natural to add mistakenly:
  -- Don't do this for double quotes, as adding an extra in that
  -- case is likely to be a sign of a more serious oversight.
  -- (If the delimiter is a single quote, no need to test, as those are always all consumed.)
  if capture ~= '"' and character ~= "'" and subject:sub(position + offset, position + offset) == "'" then
    offset = offset + 1
  end

  return position + offset, result
end

return Cp() * Cmt(P(literals.delim.string1) + literals.delim.string2, captureString) * common.endToken