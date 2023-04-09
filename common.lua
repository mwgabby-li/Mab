local lpeg = require "lpeg"

local common = {}

local furthestMatch = 0

common.endToken = lpeg.locale().space^0 * 
                  -- Track furthest match after every token!
                  lpeg.P(
                    function (_,position)
                      furthestMatch = math.max(furthestMatch, position)
                      return true
                    end)

function common.getFurthestMatch()
  return furthestMatch
end

function common.I (tag)
    return lpeg.P(function ()
        print(tag)
        return true
    end)
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
    for line in poem:gmatch('([^\r\n]*)[\r]?[\n]') do
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