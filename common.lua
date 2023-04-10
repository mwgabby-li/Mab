local lpeg = require "lpeg"
local symbols = require "symbols"

local P = lpeg.P

local common = {}

local furthestMatch = 0

common.endToken = (lpeg.locale().space + symbols.comments.line)^0  *
                  -- Track furthest match after every token!
                  P(
                    function (_,position)
                      furthestMatch = math.max(furthestMatch, position)
                      return true
                    end)

function common.getFurthestMatch()
  return furthestMatch
end

function common.I (tag)
    return P(function ()
        print(tag)
        return true
    end)
end

function common.lines(string, include_newlines)
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
