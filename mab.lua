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

if arg[1] ~= nil and (string.lower(arg[1]) == '--tests') then
  common.poem(true)
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
local ast, errorMessage = parser.parse(input, parameters.pegdebug)
print(string.format('         %s: %0.2f milliseconds.', ast and 'complete' or '  FAILED', (os.clock() - start) * 1000))

if errorMessage then
  io.stderr:write('Unable to continue ' .. errorMessage)
  io.stderr:write('Failed to generate AST from input.\n')
  return 1
end

if parameters.show.AST then
  print '\nAST:'
  print(pt.pt(ast, {'version', 'tag', 'name', 'identifier', 'assignment', 'value', 'firstChild', 'op', 'child', 'secondChild', 'body', 'sentence', 'position'}))
end

if parameters.show.graphviz then
  io.write '\nGraphviz AST...'
  start = os.clock()
  local graphviz, errors = graphviz.translate(ast)
  print(string.format('    %s: %0.2f milliseconds.', (#errors == 0) and 'complete' or '  FAILED', (os.clock() - start) * 1000))
  if #errors > 0 then
    for _, errorTable in ipairs(errors) do
      -- backup = false (positions for type errors are precise)
      if errorTable.position then
        io.write(common.generateErrorMessage(input, errorTable.position, false, 'On line '))
      end
      io.write(errorTable.message)
      io.write'\n\n'
    end
  else
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
  io.write '\nType checking...'
  start = os.clock()
  local errors = typeChecker.check(ast)
  print(string.format('   %s: %0.2f milliseconds.', (#errors == 0) and 'complete' or '  FAILED', (os.clock() - start) * 1000))
  if #errors > 0 then
    for _, errorTable in ipairs(errors) do
      -- backup = false (positions for type errors are precise)
      if errorTable.position then
        io.write(common.generateErrorMessage(input, errorTable.position, false, 'On line '))
      end
      io.write(errorTable.message)
      io.write'\n\n'
    end

    return 1
  end
else
  print '\nType checking...    skipped: WARNING! ONLY USE FOR MAB LANGUAGE DEVELOPMENT.'
end

io.write '\nTranslating...'
start = os.clock()
local code, errors = toStackVM.translate(ast)
print(string.format('     %s: %0.2f milliseconds.', (code and #errors == 0) and 'complete' or '  FAILED', (os.clock() - start) * 1000))

if not code or #errors > 0 then
  for _, errorTable in ipairs(errors) do
    -- backup = false (positions for type errors are precise)
    if errorTable.position then
      io.write(common.generateErrorMessage(input, errorTable.position, false, 'On line '))
    end
    io.write(errorTable.message)
    io.write'\n\n'
  end
  return 1
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
local result, errors = interpreter.execute(code, trace)
print(string.format('         Execution %s: %0.2f milliseconds.', (result ~= nil and #errors == 0) and 'complete' or '  FAILED', (os.clock() - start) * 1000))

if result == nil or #errors > 0 then
  for _, errorTable in ipairs(errors) do
    io.write(errorTable.message)
    io.write'\n\n'
  end
  return 1
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
if parameters.show.result then
  print '\nResult:'
  print(result)
end
