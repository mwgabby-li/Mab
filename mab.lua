#!/usr/bin/env lua

package.path = package.path .. ';1 Parser/?.lua'
package.path = package.path .. ';1 Parser/Components/?.lua'
package.path = package.path .. ';2 Type Checker/?.lua'
package.path = package.path .. ';3 Translators/?.lua'
package.path = package.path .. ';4 Interpreter/?.lua'

local parser = require 'parser'
local typeChecker = require 'typechecker'
local toStackVM = require 'toStackVM'
local graphviz = require 'toGraphviz'
local interpreter = require 'stackVM'

local pt = require 'External.pt'
local common = require 'common'

phases = {
  parser = {
    action = parser.parse,
    name = 'Parser',
    actionName = 'parsing',
    inputName = 'source code',
  },

  typeChecker = {
    action = typeChecker.check,
    name = 'Type Checker',
    actionName = 'type checking',
    inputName = 'AST',
    version = 3763314777,
  },

  graphviz = {
    action = graphviz.translate,
    name = 'Graphviz AST',
    actionName = 'generating GraphViz file',
    inputName = 'AST',
    version = 0,
  },

  toStackVM = {
    action = toStackVM.translate,
    name = 'Stack VM',
    actionName = 'generating Stack VM code',
    inputName = 'AST',
    version = 3763314777,
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
    version = 218216203,
  },
}

function runPhase(phaseTable, phaseInput, parameters)
  
  if not phaseTable.separatedOutput then
    local extraBuffer = 13 - #phaseTable.name
    io.write('\n'..phaseTable.name..'...'..(' '):rep(extraBuffer))
  else
    io.write('\n'..phaseTable.name..' starting...\n\n')
  end
  
  start = os.clock()
  errorReporter, result, extra = phaseTable.action(phaseInput, parameters)
  local success = result and errorReporter:count() == 0
  if not phaseTable.separatedOutput then
    io.write(string.format('%s: %7.2f milliseconds.\n', success and 'complete' or '  FAILED', (os.clock() - start) * 1000))
  else
    local extraBuffer = 11 - #phaseTable.name
    io.write(string.format('\n'..(' '):rep(extraBuffer)..phaseTable.name..' %s: %7.2f milliseconds.\n', 
                           success and 'completed in' or 'FAILED after', (os.clock() - start) * 1000))
  end
  io.flush()

  mismatchAndFailure, mismatchAndSuccess = common.maybeCreateMismatchMessages(phaseInput, phaseTable)

  if not success then
    if mismatchAndFailure then
      io.stderr:write(mismatchAndFailure..'\n\n')
    end

    errorReporter:outputErrors(parameters.subject, parameters.inputFile)
  elseif mismatchAndSuccess then
    io.stderr:write(mismatchAndSuccess..'\n\n')
  end
  
  io.stderr:flush()

  return success, result, extra
end

if arg[1] ~= nil and (string.lower(arg[1]) == '--tests') then
  print(common.poem(true))
  arg[1] = nil
  local lu = require 'External.luaunit'
  testFrontend = require 'tests':init(parser.parse, typeChecker, toStackVM, interpreter)

  os.exit(lu.LuaUnit.run())
end

local parameters = { show = {}, typechecker = true }
local awaiting_filename = false
for index, argument in ipairs(arg) do
  if awaiting_filename then
    local status, err = pcall(io.input, arg[index])
    parameters.inputFile = arg[index]
    if not status then
      print('Could not open file "' .. arg[index] .. '"\n\tError: ' .. err)
      os.exit(1)
    end
    awaiting_filename = false
  elseif argument:lower() == '--input' or argument:lower() == '-i' then
    awaiting_filename = true
  elseif argument:lower() == '--tests' then
    print('-tests must be the first argument if it is being sent in.')
    os.exit(1)
  elseif argument:lower() == '--ast' or argument:lower() == '-a' then
    parameters.show.AST = true
  elseif argument:lower() == '--code' or argument:lower() == '-c' then
    parameters.show.code = true
  elseif argument:lower() == '--trace' or argument:lower() == '-t' then
    parameters.show.trace = true
  elseif argument:lower() == '--result' or argument:lower() == '-r' then
    parameters.show.result = true
  elseif argument:lower() == '--echo-input' or argument:lower() == '-e' then
    parameters.show.input = true
  elseif argument:lower() == '--graphviz' or argument:lower() == '-g' then
    parameters.show.graphviz = true
  elseif argument:lower() == '--pegdebug' or argument:lower() == '-p' then
    parameters.pegdebug = true
  elseif argument:lower() == '--stop-at-first-error' or argument:lower() == '-s' then
    parameters.stopAtFirstError = true
  elseif argument:lower() == '--type-checker-off' or argument:lower() == '-y' then
    parameters.typechecker = false
  else
    print('Unknown argument ' .. argument .. '.')
    os.exit(1)
  end
end

if awaiting_filename then
  print 'Specified -i, but no input file found.'
  os.exit(1)
end

print(common.poem())

local subject = io.read 'a'
if parameters.show.input then
  print 'Input:'
  print(subject)
end
parameters.subject = subject

local success, ast = runPhase(phases.parser, subject, parameters)
if not success then
  io.stderr:write('Unable to continue. Failed to generate AST from input.\n')
  return 1
end

if parameters.show.AST then
  print '\nAST:'
  print(pt.pt(ast, {'version', 'tag', 'scope', 'parameters', 'type_', 'name', 'identifier', 'value', 'assignment', 'firstChild', 'op', 'child', 'secondChild', 'body', 'sentence', 'position'}))
end

local typeCheckerSuccess = true
if parameters.typechecker then
  typeCheckerSuccess = runPhase(phases.typeChecker, ast, parameters)
  if typeCheckerSuccess == false then
    io.stderr:write('Type checking failed. Will abort after GraphViz (if enabled.)\n')
    io.stderr:flush()
  end
else
  print '\nType checking...    skipped: WARNING! ONLY USE FOR MAB LANGUAGE DEVELOPMENT.'
  io.flush()
end

if parameters.show.graphviz then
  local success, graphviz = runPhase(phases.graphviz, ast, parameters)

  if success then
    local prefix = parameters.inputFile or 'temp'
    local dotFileName = prefix .. '.dot'
    local dotFile = io.open(dotFileName, 'wb')
    dotFile:write(graphviz)
    dotFile:close()
    local svgFileName = prefix .. '.svg'
    os.execute('dot ' .. '"' .. dotFileName .. '" -Tsvg -o "' .. svgFileName .. '"')
    os.execute('firefox "'.. svgFileName .. '" &')
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

local success, code = runPhase(phases.toStackVM, ast, parameters)

if not success then
  io.stderr:write('Unable to continue. Failed to generate StackVM code from AST.\n')
  return 1
end

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
        print('\t\t\t' .. tostring(trace.stack[k][i]))
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