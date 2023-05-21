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
      local character = input:sub(position - 1, position - 1)
      while character:find('%s') ~= nil do
        
        if character == '\n' then
          errorLine = errorLine - 1
          -- On \r\n systems, we need to backtrack twice since there are two characters in a line ending,
          -- so we will be at the same place visually as on \n systems.
          if input:sub(position - 1, position - 1) == '\r' then
            position = position - 1
          end
        end
        position = position - 1
        backedUp = true
        prefix = backedUpPrefix or (prefix or '')
        character = input:sub(position - 1, position - 1)
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
    for k, v in pairs(object) do result[common.copyObjectNoSelfReferences(k)] = common.copyObjectNoSelfReferences(v) end
    return result
end

function common.maybeCreateMismatchMessages(input, phaseTable)
  if phaseTable.version == nil then return end
  
  if input.version ~= phaseTable.version then
    return ' Errors while '..phaseTable.actionName..
            '. Note that the '..phaseTable.inputName..' version '..input.version..
            ' mismatches the known compatible version '..phaseTable.version..'.',
           ' Warning! '..phaseTable.name..' expected '..phaseTable.inputName..' version '..phaseTable.version..
            ' but got '..input.version..'.'
  end
end

local parserVersionHash = false
function common.parserVersionHash()
  if not parserVersionHash then
    local file = io.open('1 Parser/parser.lua', 'r')
    local parser = file:read('*all')
    file:close()
    -- Remove \r so that the hash will be the same on Windows and Linux/MacOS
    parser:gsub('\r', '')
    parserVersionHash = common.hash(parser)
  end
  return parserVersionHash
end

local toStackVMVersionHash = false
function common.toStackVMVersionHash()
  if not toStackVMVersionHash then
    local file = io.open('3 Translators/toStackVM.lua', 'r')
    local translator = file:read('*all')
    file:close()
    -- Remove \r so that the hash will be the same on Windows and Linux/MacOS
    translator:gsub('\r', '')
    toStackVMVersionHash = common.hash(translator, common.parserVersionHash())
  end
  return toStackVMVersionHash
end

-- Numbers less than ten are spelled out.
-- You can also pass in a label that becomes plural with 's' and it will become a matching suffix.
-- e.g.:
-- local packetCount = 9
-- toReadableNumber(packetCount, 'packet')
-- will become: 'nine packets'
-- and
-- packetCount = 1
-- toReadableNumber(packetCount, 'packet')
-- will become: 'one packet'
function common.toReadableNumber(number, singular)
  local abs = math.abs(number)
  local prefix = number < 0 and ' negative' or ''
  local suffix = singular ~= nil and ' '..(number == 1 and singular or singular..'s') or ''
  
  if abs > 9 then
    return tostring(number)..suffix
  elseif abs == 0 then
    return 'zero'..suffix
  elseif abs == 1 then
    return prefix..'one'..suffix
  elseif abs == 2 then
    return prefix..'two'..suffix
  elseif abs == 3 then
    return prefix..'three'..suffix
  elseif abs == 4 then
    return prefix..'four'..suffix
  elseif abs == 5 then
    return prefix..'five'..suffix
  elseif abs == 6 then
    return prefix..'six'..suffix
  elseif abs == 7 then
    return prefix..'seven'..suffix
  elseif abs == 8 then
    return prefix..'eight'..suffix
  elseif abs == 9 then
    return prefix..'nine'..suffix
  else
    return tostring(number)..suffix
  end
end

function common.hash(string, start)
  start = start or 1484741823
  assert(#string <= 1000000, "Hash fail, {string:byte(1,-1) doesn't work with strings over 1 million bytes long.")
  local stringBytes = {string:byte(1,-1)}
  local hash = ~(start & #string)
  for i = 1,#stringBytes do
    local byte = stringBytes[i]
    
    addByte = (hash<<5) + ((0xFFFFFFFF & hash) >>2) + byte
    
    hash = (hash | addByte) & (0xFFFFFFFF & (~(hash & addByte)))
  end
  return hash
end

-- Error reporter is separate, even for the type checker phase,
-- which only exists to generate errors.
-- This is necessary or we can't get the errors that were output
-- if an exception is thrown within the phase pcall()s.
-- And in fact, the Error Reporter itself does these pcall()s.
common.ErrorReporter = {}

function common.ErrorReporter:new(o)
  o = o or {
    errors = {},
  }
  self.__index = self
  setmetatable(o, self)
  return o
end

function common.ErrorReporter:addError(message, tableWithPositionOrPositionOrNil)
  local position = type(tableWithPositionOrPositionOrNil) == 'table' and
                   tableWithPositionOrPositionOrNil.position or
                   tableWithPositionOrPositionOrNil

  self.errors[#self.errors + 1] = {
    message = message,
    position = position,
  }
end

function common.ErrorReporter:count()
  return #self.errors
end

function common.ErrorReporter:outputErrors(input, filename)
  for _, errorTable in ipairs(self.errors) do
    -- backup = false (positions for type errors are precise)
    if errorTable.position then
      io.stderr:write(common.generateErrorMessage(input, errorTable.position, false, filename and filename..':' or 'On line '))
    end
    io.stderr:write(errorTable.message)
    io.stderr:write'\n\n'

    if self.stopAtFirstError then
      io.write 'Stopping at first error, as requested.\n'
      break
    end
  end
end

function common.ErrorReporter:pcallAddErrorOnFailure(...)
  local result, message = pcall(...)
  if result == false then
    self:addError('Internal error: '..message)
    return false
  end

  return message
end

-- Calculate these here so that compile timings don't reflect hashing a file.
common.parserVersionHash()
common.toStackVMVersionHash()

return common
