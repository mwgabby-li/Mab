#!/usr/bin/env lua

package.path = package.path .. ';1 Parser/?.lua'
package.path = package.path .. ';1 Parser/Components/?.lua'
package.path = package.path .. ';2 Type Checker/?.lua'
package.path = package.path .. ';3 Translators/?.lua'
package.path = package.path .. ';4 Interpreter/?.lua'
package.path = package.path .. ';Text/?.lua'

local parser = require 'parser'
local typeChecker = require 'typechecker'
local toStackVM = require 'toStackVM'
local toGraphviz = require 'toGraphviz'
local interpreter = require 'stackVM'

local pt = require 'External.pt'
local common = require 'common'

local phases = {
  parser = {
    action = parser.parse,
    name = 'Parser',
    actionName = 'parsing',
    inputName = 'source code',
    abortOnFailure = 'Failed to generate AST from input.',
  },

  typeChecker = {
    action = typeChecker.check,
    name = 'Type Checker',
    actionName = 'type checking',
    inputName = 'AST',
    version = 1052957823,
  },

  graphviz = {
    action = toGraphviz.translate,
    name = 'Graphviz AST',
    actionName = 'generating GraphViz file',
    inputName = 'AST',
    version = 1052957823,
  },

  toStackVM = {
    action = toStackVM.translate,
    name = 'Stack VM',
    actionName = 'generating Stack VM code',
    inputName = 'AST',
    version = 1052957823,
    abortOnFailure = 'Failed to generate StackVM code from AST.',
  },

  interpreter = {
    action = interpreter.execute,
    name = 'Interpreter',
    actionName = 'interpreting',
    inputName = 'Stack VM code',
    -- Prints 'starting' and then leaves space
    -- for the program to output, then prints
    -- the completion message.
    separatedOutput = true,
    version = 246844683,
  },
}

function runPhase(phaseTable, phaseInput, parameters)
  if not phaseInput then
    io.stderr:write('\n'..phaseTable.name..' cannot start, no input.')

    if parameters.abortOnFailure then
      io.stderr:write(' Unable to continue.\n')
      os.exit(1)
    else
      io.stderr:write '\n'
      return
    end
  end

  if parameters.verbose then
    if not phaseTable.separatedOutput then
      local extraBuffer = 14 - #phaseTable.name
      io.write('\n'..phaseTable.name..'...'..(' '):rep(extraBuffer))
    else
      io.write('\n'..phaseTable.name..' starting...\n\n')
    end
  end
  
  local start = os.clock()
  local errorReporter, result, extra = phaseTable.action(phaseInput, parameters)
  local success = result and errorReporter:count() == 0

  local message
  -- We allow only allow unified output in verbose mode.
  if not phaseTable.separatedOutput and parameters.verbose then
    message = (string.format('%s: %7.2f milliseconds.\n',
               success and 'complete' or '  FAILED',
               (os.clock() - start) * 1000))
  -- If not in verbose mode, we only print the message if the phase failed,
  -- and we print the whole thing at once, never in two pieces.
  else
    local extraBuffer = 12 - #phaseTable.name
    message = string.format('\n'..(' '):rep(extraBuffer)..phaseTable.name..
                            ' %s: %7.2f milliseconds.\n',
                            success and 'completed in' or 'FAILED after',
                            (os.clock() - start) * 1000)
  end

  if success and parameters.verbose then
    io.write(message)
  elseif not success then
    io.stderr:write(message)
  end

  local mismatchAndFailure, mismatchAndSuccess = common.maybeCreateMismatchMessages(phaseInput, phaseTable)

  if not success then
    if mismatchAndFailure then
      io.stderr:write(mismatchAndFailure..'\n\n')
    end

    errorReporter:outputErrors(parameters.subject, parameters.inputFile)
    if parameters.abortOnFailure then
      io.stderr:write('Unable to continue. '..parameters.abortOnFailure..'\n')
      os.exit(1)
    end
  elseif mismatchAndSuccess then
    io.stderr:write(mismatchAndSuccess..'\n\n')
  end
  
  return success, result, extra
end

if arg[1] ~= nil and (string.lower(arg[1]) == '--tests') then
  print(common.poem(true))
  arg[1] = nil
  local lu = require 'External.luaunit'
  testFrontend = require 'tests':init(parser.parse, typeChecker, toGraphviz, toStackVM, interpreter)

  os.exit(lu.LuaUnit.run())
end

local parameters = { show = {}, poetic = true }
local awaiting_filename = false

local function readOption(argument)
  if awaiting_filename then
    local defaultInput = io.input()
    local status, err = pcall(io.input, argument)
    if not status then
      io.stderr:write('Could not open file "' .. argument .. '"\n\tError: ' .. err..'\n')
      os.exit(1)
    else
      parameters.inputFile = argument
      parameters.subject = io.read 'a'
      io.close()
    end
    io.input(defaultInput)
    awaiting_filename = false
  elseif argument == '--input' or argument == '-i' then
    awaiting_filename = true
  elseif argument == '--tests' then
    io.stderr:write('--tests must be the first argument if it is being sent in.\n')
    os.exit(1)
  elseif argument == '--ast' or argument == '-a' then
    parameters.show.AST = true
  elseif argument == '--unpoetic' or argument == '-u' then
    parameters.poetic = false
  elseif argument == '--verbose' or argument == '-v' then
    parameters.verbose = true
  elseif argument == '--code' or argument == '-c' then
    parameters.show.code = true
  elseif argument == '--trace' or argument == '-t' then
    parameters.show.trace = true
  elseif argument == '--result' or argument == '-r' then
    parameters.show.result = true
  elseif argument == '--echo-input' or argument == '-e' then
    parameters.show.input = true
  elseif argument == '--graphviz' or argument == '-g' then
    parameters.show.graphviz = true
  elseif argument == '--pegdebug' or argument == '-p' then
    parameters.pegdebug = true
  elseif argument == '--stop-at-first-error' or argument == '-s' then
    parameters.stopAtFirstError = true
  else
    io.stderr:write('Unknown argument ' .. argument .. '.\n')
    os.exit(1)
  end  
end

for _, argument in ipairs(arg) do
  if awaiting_filename then
    readOption(argument)
  elseif argument:find('^[-][-]') then
    readOption(argument)
  elseif argument:find('^[-]') then
    local numOptions =  #argument - 1
    for i = 1, numOptions do
      readOption('-'..argument:sub(i+1,i+1))
    end
  -- Let's assume this is a filename.
  else
    awaiting_filename = true
    readOption(argument)
  end
end

if awaiting_filename then
  io.stderr:write('Specified -i, but no input file found.\n')
  os.exit(1)
end

if parameters.verbose or parameters.poetic then
  print(common.poem())
end

local subject = parameters.subject or io.read 'a'
if parameters.show.input then
  print 'Input:'
  print(subject)
end

local _, ast = runPhase(phases.parser, subject, parameters)

if parameters.show.AST then
  print '\nAST:'
  print(pt.pt(ast, {'version', 'tag', 'scope', 'parameters', 'type_', 'name', 'identifier', 'value', 'assignment', 'firstChild', 'op', 'child', 'secondChild', 'body', 'sentence', 'position'}))
end

local typeCheckerSuccess = runPhase(phases.typeChecker, ast, parameters)

if parameters.show.graphviz then
  local success, graphviz = runPhase(phases.graphviz, ast, parameters)

  if success then
    local prefix = parameters.inputFile or 'temp'
    local dotFileName = prefix .. '.dot'
    local dotFile = io.open(dotFileName, 'w')
    dotFile:write(graphviz)
    dotFile:close()
    local svgFileName = prefix .. '.svg'
    local retries = 5
    for i=1,retries do
      local result = os.execute('dot ' .. '"' .. dotFileName .. '" -Tsvg -o "' .. svgFileName .. '"')
      if result then
        break
      else
        -- GraphViz has been known to crash on valid input.
        io.stderr:write('GraphViz failure. Retry attempt '..i..' of '..retries..'...\n')
      end
    end
    os.execute('"'.. svgFileName .. '" &')
  else
    io.stderr:write('GraphViz failed.')
    if typeCheckerSuccess then
      io.stderr:write ' Continuing...'
    end
    io.stderr:write '\n'
  end
end

-- Bail out from type checking here, so we can run things in order,
-- but still show GraphViz.
if not typeCheckerSuccess then
  return 1
end

local _, code = runPhase(phases.toStackVM, ast, parameters)

if parameters.show.code then
  print '\nGenerated code:'
  print(pt.pt(code))
end

local success, result, trace = runPhase(phases.interpreter, code, parameters)

if trace then
  print '\nExecution trace:'
  for k, v in ipairs(trace) do
    print(k, v)

    if trace.stack[k] then
      for i = #trace.stack[k],1,-1 do
        print('\t\t\t' .. tostring(trace.stack[k][i].value)..(trace.stack[k][i].base==i and ' -' or ''))
      end
      if #trace.stack[k] == 0 then
        print '\t\t\t(empty)'
      end
    end
  end
end
if parameters.show.result and result ~= nil then
  print '\nResult:'
  print(result)
end

-- Return 1 to indicate failure.
if not success then
  return 1
end