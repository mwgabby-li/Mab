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

local versions = {
  AST = { TypeChecker = 4059075351,
          GraphViz = 34989090030,
          StackVM = 4059075351 },
  code = { StackVM = 1422448217 },
}

local pt = require 'External.pt'
local common = require 'common'

if arg[1] ~= nil and (string.lower(arg[1]) == '--tests') then
  print(common.poem(true))
  arg[1] = nil
  local lu = require 'External.luaunit'
  testFrontend = require 'tests':init(parser.parse, typeChecker, toStackVM, interpreter)

  os.exit(lu.LuaUnit.run())
end

local parameters = { show = {}, typechecker = true }
local input_file
local awaiting_filename = false
for index, argument in ipairs(arg) do
  if awaiting_filename then
    local status, err = pcall(io.input, arg[index])
    input_file = arg[index]
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
    parameters.stopAtFirst = true
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

local input = io.read 'a'
if parameters.show.input then
  print 'Input:'
  print(input)
end
io.write 'Parsing...'
local start = os.clock()
local pcallResult, ast, errorMessage = pcall(parser.parse, input, parameters.pegdebug)
print(string.format('         %s: %0.2f milliseconds.', (pcallResult and ast) and 'complete' or '  FAILED', (os.clock() - start) * 1000))

if not pcallResult then
  print("Internal error: " .. ast)
elseif errorMessage then
  io.stderr:write('Unable to continue ' .. errorMessage)
  io.stderr:write('Failed to generate AST from input.\n')
  return 1
end

if parameters.show.AST then
  print '\nAST:'
  print(pt.pt(ast, {'version', 'tag', 'scope', 'parameters', 'type_', 'name', 'identifier', 'value', 'assignment', 'firstChild', 'op', 'child', 'secondChild', 'body', 'sentence', 'position'}))
end

local errorReporter = common.ErrorReporter:new()

-- GraphViz is a translator, but run it before type checking so that we can visualize even type-invalid ASTs.
if parameters.show.graphviz then
  local mismatchAndErrors, mismatchNoErrors = common.maybeCreateMismatchMessages(ast, versions.AST.GraphViz, 'generating GraphViz file', 'AST')

  io.write '\nGraphviz AST...'
  start = os.clock()
  graphviz.translate(ast, errorReporter)
  print(string.format('    %s: %0.2f milliseconds.', errorReporter:count() == 0 and 'complete' or '  FAILED', (os.clock() - start) * 1000))

  if errorReporter:count() > 0 then
    if mismatchAndErrors then
      print(mismatchAndErrors)
    end

    -- clear errors = true
    errorReporter:outputErrors(input, parameters.stopAtFirst, true)
  else
    if mismatchNoErrors then
      print(mismatchNoErrors)
    end
    local prefix = input_file or 'temp'
    local dotFileName = prefix .. '.dot'
    local dotFile = io.open(dotFileName, 'wb')
    dotFile:write(graphviz)
    dotFile:close()
    local svgFileName = prefix .. '.svg'
    os.execute('dot ' .. '"' .. dotFileName .. '" -Tsvg -o "' .. svgFileName .. '"')
    os.execute('firefox "'.. svgFileName .. '" &')
  end
end

if parameters.typechecker then
  local mismatchAndErrors, mismatchNoErrors = common.maybeCreateMismatchMessages(ast, versions.AST.TypeChecker, 'type checking', 'AST')

  io.write '\nType checking...'
  start = os.clock()
  typeChecker.check(ast, errorReporter)
  print(string.format('   %s: %0.2f milliseconds.', errorReporter:count() == 0 and 'complete' or '  FAILED', (os.clock() - start) * 1000))
  if errorReporter:count() > 0 then
    if mismatchAndErrors then
      print(mismatchAndErrors)
    end

    -- clear errors = true
    errorReporter:outputErrors(input, parameters.stopAtFirst, true)
    return 1
  elseif mismatchNoErrors then
    print(mismatchNoErrors)
  end
else
  print '\nType checking...    skipped: WARNING! ONLY USE FOR MAB LANGUAGE DEVELOPMENT.'
end

io.write '\nTranslating...'
start = os.clock()
local code = toStackVM.translate(ast)
local success = code and errorReporter:count() == 0
print(string.format('     %s: %0.2f milliseconds.', success and 'complete' or '  FAILED', (os.clock() - start) * 1000))

local mismatchAndErrors, mismatchNoErrors = common.maybeCreateMismatchMessages(ast, versions.AST.StackVM, 'translating to StackVM code', 'AST')

if not success then
  if mismatchAndErrors then
    print(mismatchAndErrors)
  end

  -- clear errors = true
  errorReporter:outputErrors(input, parameters.stopAtFirst, true)
  return 1
elseif mismatchNoErrors then
  print(mismatchNoErrors)
end

if parameters.show.code then
  print '\nGenerated code:'
  print(pt.pt(code))
end

print '\nExecuting...'
start = os.clock()
local trace = nil
if parameters.show.trace then
  trace = {}
end
local result = interpreter.execute(code, trace, errorReporter)
local success = code and errorReporter:count() == 0
print(string.format('         Execution %s: %0.2f milliseconds.', success and 'complete' or '  FAILED', (os.clock() - start) * 1000))

local mismatchAndErrors, mismatchNoErrors = common.maybeCreateMismatchMessages(code, versions.code.StackVM, 'executing StackVM code', 'code')

if not success then
  if mismatchAndErrors then
    print(mismatchAndErrors)
  end

  -- clear errors = true
  errorReporter:outputErrors(input, parameters.stopAtFirst, true)
elseif mismatchNoErrors then
  print(mismatchNoErrors)
end

if parameters.show.trace then
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
if not pcallResult or result == nil or #errors > 0 then
  return 1
end