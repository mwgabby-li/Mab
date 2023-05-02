local lpeg = require "lpeg"
local literals = require 'literals'

local P = lpeg.P
local V = lpeg.V

local common = {}


common.endToken = V'endToken'

function common.I (tag)
    return P(function ()
        print(tag)
        return true
    end)
end


local lineComment = literals.comments.startLine * (P(1) - '\n')^0
local blockComment = literals.comments.openBlock *
      (P(1) - P(literals.comments.closeBlock))^0 * literals.comments.closeBlock
local furthestMatch = 0
common.endTokenPattern = (lpeg.locale().space + blockComment + lineComment)^0  *
                          -- Track furthest match after every token!
                          P(
                            function (_,position)
                              furthestMatch = math.max(furthestMatch, position)
                              return true
                            end
                          )

function common.testGrammar(pattern)
  return P{pattern * -1, endToken=common.endTokenPattern}
end

function common.getFurthestMatch()
  return furthestMatch
end

function common.clearFurthestMatch()
  furthestMatch = 0
end

function common.lines(string, include_newlines)
  -- Add a extra newline at the end of the string so that the final line will have a newline.
  -- If we don't do this, the last line will not be output by our matches.
  if string:sub(#string, #string) ~= '\n' then
    string = string .. '\n'
  end
  
  if include_newlines then
    return string:gmatch('[^\r\n]*[\r]?[\n]')
  else
    return string:gmatch('([^\r\n]*)[\r]?[\n]')
  end
end

-- Counts the number of occurrences of substring in string
function common.count(substring, string)
    local matches = 0
    ((P(substring)/function() matches = matches + 1 end + 1)^0):match(string)
    return matches
end

function common.poem(all)
    local poem =
[[In dreams, Queen Mab arrives unseen,
A dainty fairy, slight and lean.
Upon a carven hazelnut,
With insect steeds, reigns finely cut.

Through slumber's realm, she softly flies,
Bestowing dreams before our eyes.
To lovers' hearts, brings sweet amour,
To soldiers, scenes of battles' roar.

Beware her touch, enchanting still,
For fickle fate may bend at will.
In dreams, delight may find its cost,
As morning breaks, and all is lost.
]]
    if all then
        return poem
    end
    local lines = {}
    for line in common.lines(poem) do
      lines[#lines + 1] = line
    end
    math.randomseed(os.time())
    local startSelection = math.random(1, #lines)
    if lines[startSelection] == '' then
      startSelection = startSelection + 1
    end
    local startToEnd = #lines - startSelection
    local endSelection = startSelection + math.min(math.random(1, #lines), startToEnd)
    if lines[endSelection] == '' then
      endSelection = endSelection - 1
    end

    local result = ''
    for i = startSelection, endSelection do
      result = result .. lines[i] .. '\n'
    end
  
    return result
end

-- defaultPrefix: Used when backup does not occur.
-- backedUpPrefix: Used when backup occurs.
function common.generateErrorMessage(input, position, backup, defaultPrefix, backedUpPrefix)
    local errorMessage = ''
    
    -- Count the number of newlines - the number of line breaks plus one is the current line
    local newlineCount = common.count('\n', input:sub(1, position ))
    local errorLine = newlineCount + 1

    -- If the previous character was a newline, this means we (sort of) failed at the end of the line.
    -- Show the failure on the previous line, and one character back so that the caret is after the last character
    -- on that line.    
    local backedUp = false
    local prefix = defaultPrefix or ''
    if backup then
      while input:sub(position - 1, position - 1) == '\n' do
        errorLine = errorLine - 1
        position = position - 1
        -- On \r\n systems, we need to backtrack twice since there are two characters in a line ending,
        -- so we will be at the same place visually as on \n systems.
        if input:sub(position - 1, position - 1) == '\r' then
          position = position - 1
        end
        backedUp = true
        prefix = backedUpPrefix or (prefix or '')
      end
    end

    errorMessage = errorMessage .. (prefix .. errorLine .. ':\n')

    local contextAfter = 2
    local contextBefore = 2

    local lineNumber = 1
    
    -- Keep track of the current character in the subject, since we're breaking things into lines
    local currentCharacter = 0
    -- Number of digits tells us how much padding we should add to line numbers so they line up
    local digits = math.ceil(math.log10(errorLine + contextAfter))
    local includeNewlines = true
    for line in common.lines(input, includeNewlines) do
      if lineNumber >= errorLine - contextBefore and lineNumber <= errorLine + contextAfter then
        local lineNumberPrefixed = string.format('%'..(digits)..'d',lineNumber) 
        if lineNumber == errorLine then
          local failureCharacter = position - currentCharacter
          errorMessage = errorMessage .. ('>' .. lineNumberPrefixed .. ' ' .. line)
          errorMessage = errorMessage .. (' ' .. string.rep(' ', #lineNumberPrefixed) .. string.rep(' ', failureCharacter) .. '^\n') 
        else
          errorMessage = errorMessage .. (' ' .. lineNumberPrefixed .. ' ' .. line)
        end
      end
      
      lineNumber = lineNumber + 1
      currentCharacter = currentCharacter + #line
    end
    
    return errorMessage
end

function common.copyObjectNoSelfReferences(object)
    if type(object) ~= 'table' then return object end
    local result = {}
    for k, v in pairs(object) do result[copyObjectNoSelfReferences(k)] = copyObjectNoSelfReferences(v) end
    return result
end

return common
