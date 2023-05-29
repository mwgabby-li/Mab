local LPeg = require 'lpeg'
local common = require 'common'
local numeral = require 'numeral'

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
  -- Escapes are:
  -- a for bell.
  -- b for backspace.
  -- f for form feed.
  -- n for newline.
  -- r for carriage return.
  -- t for horizontal tab.
  -- v for vertical tab.
  -- [1-9] for that many repeats of the original character. (Up to nine.)
  --       While the ending may be specified in the beginning of the string as:
  --       start number character (where start is the single quote character)
  --       this will repeat only the character itself n times.
  --       For double-quoted strings, this will repeat the double quote n times.
  -- 0 for null. (Technically \0 is null in 'base 8')
  -- 0[1-9]+ for a character literal in base 8.
  -- [xX][0-9a-fA-F]+ for a character literal in base 16.

  -- A string starting with double quotes continues until a double
  -- quote not followed by an escape sequence.
  local result, escape, character, number, offset
  if capture == '"' then
    character = '"'
    number = 1
    offset = 0
  else
    -- A string starting with two single quotes continues until two single
    -- quotes not followed by an escape sequence.
    -- A string starting with a single quote, then a number n, 
    -- then a special character, will end when n repetitions of the special
    -- character are not followed by an escape sequence.
    -- Two single quotes is actually the same as writing a string in the second format like so:
    --  '2'This is a string ending in two single quotes.''
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
  -- Default to 2 repeats for the escape if the 'character' is a single quote,
  -- otherwise default to 1.
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
    if result:sub(1, 1) == '\r' then
      -- \r\n, start at the third character, 
      -- the first character after the \r\n.
      result = result:sub(3)
    else
      -- Only \n, start at the second character, 
      -- the first character after the newline.
      result = result:sub(2)
    end
  end

  -- Do all escapes
  result = result:gsub(escape..'a', '\a')
  result = result:gsub(escape..'b', '\b')
  result = result:gsub(escape..'f', '\f')
  result = result:gsub(escape..'n', '\n')
  result = result:gsub(escape..'r', '\r')
  result = result:gsub(escape..'t', '\t')
  result = result:gsub(escape..'v', '\v')
  result = result:gsub(escape..'s', character)
  result = result:gsub(escape..'[xX0][0-9]+', toLiteral)
  result = result:gsub('('..escape..')([1-9])', toRepeats)

  return position + offset, result
end

return Cp() * Cmt(P"'" + '"', captureString) * common.endToken