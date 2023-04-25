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
        print(poem)
        return
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

    for i = startSelection, endSelection do
      print(lines[i])
    end
end

return common
