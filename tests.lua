-- Mab Frontend Test Suite (AST generation)
local lu = require 'External.luaunit'
-- Most recent supported version
local astVersion = 1
local module = {}
local entryPointName = require('literals').entryPointName

local function wrapWithEntrypoint(string)
  return 'function ' .. entryPointName .. '() {' .. string .. '}'
end

function module:fullTest(input, addEntryPoint)
  input = addEntryPoint and wrapWithEntrypoint(input) or input
  local ast = module.parse(input)
  if ast == nil then
    return 'Parsing failed!'
  end
  
  local errors = module.typeChecker.check(ast)
  if #errors > 0 then
    return 'Type checking failed!'
  end
  
  local code, errors = module.toStackVM.translate(ast)
  if code == nil or #errors > 0 then
    return 'Translation failed!'
  end
  return module.interpreter.run(code)
end

function module:init(parse, typeChecker, toStackVM, interpreter)
    module.parse = parse
    module.typeChecker = typeChecker
    module.toStackVM = toStackVM
    module.interpreter = interpreter
    return module
end

function module:testAssignmentAndParentheses()
  lu.assertEquals(self:fullTest('i = (1 + 2) * 3; return i', true), 9)
end

function module:testReturn()
  lu.assertEquals(self:fullTest('return 1 + 2', true), 3)
end

function module:testAssignmentAndReturn()
  local input = 'i = 4 * 3; return i;'
  lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testEmptyStatements()
  local input = ';;;;'
  lu.assertEquals(self:fullTest(input, true), 0)
end

function module:testEmptyInput()
  local input = ''
  lu.assertEquals(self:fullTest(input, true), 0)
end

function module:testStackedUnaryOperators()
  local input = 'i = - - - - 4 * 3; return i'
  lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testUnaryOperators()
  local input = 'i = -4 * 3; return i'
  lu.assertEquals(self:fullTest(input, true), -12)
end

function module:testEmptyStatementsLeadingTrailing()
    local input = ';;;;i = 4 * 3; return 12;;;;'
  lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testEmptyStatementsInterspersed()
  local input = ';;;;i = 4 * 3;;;;b = 12;;;;return i;;;;'
  lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testComplexSequenceResult()
    local input = 'x value = 12 / 2;'..
                  'y value = 12 * 12 / 2;'..
                  'z value = x value * y value % 12;'..
                  'z value = y value ^ x value + z value;'..
                  'return z value;'
  lu.assertEquals(self:fullTest(input, true), 139314069504)
end

function module:testExponentPrecedence()
    local input = 'i = 2 ^ 3 ^ 2; return i'
  lu.assertEquals(self:fullTest(input, true), 512)
end

function module:testBlockAndLineComments()
  local input =
[[
# Start comment

a = 10 + 4; # End of line comment
#{#} # Single-line block comment

# Block comment inside line comment: #{ blah blah blah #}

#{
# Comments nested in block comment
# Another one
b = b * 10 # Commented-out line of code
#}
b = a * a;
c = a/b;

# Disabled block comment

##{
a = a * 2;
#}
return a;
# Final comment
]]
  lu.assertEquals(self:fullTest(input, true), 28)
end

function module:testKeywordExcludeRules()
  lu.assertEquals(module.parse(wrapWithEntrypoint'return1'), nil)
  lu.assertEquals(module.parse(wrapWithEntrypoint'a = 1; returna'), nil)
  lu.assertEquals(module.parse(wrapWithEntrypoint'return = 1'), nil)
  lu.assertEquals(module.parse(wrapWithEntrypoint'return return'), nil)
  
  lu.assertEquals(self:fullTest('delta x = 1; return delta x', true), 1)
  
  lu.assertEquals(self:fullTest('return of the variable = 1; return return of the variable', true), 1)
end

function module:testFullProgram()
  local input =
[[
# a is 14
a = 10 + 4;
#{
  14 * 14 - 10 = 186
#}
b = a * a - 10;
# (186 + 10)/14
c = (b + 10)/a;
return c;
]]
  lu.assertEquals(self:fullTest(input, true), 14)
end

function module:testLessonFourEdgeCases()
  local ast = module.parse(wrapWithEntrypoint('returned = 10; return returned'))
  local code = module.toStackVM.translate(ast)
  local result = module.interpreter.run(code)
  lu.assertEquals(result, 10)
  
  lu.assertEquals(module.parse(
    [[
      x=1;
      returnx
    ]]), nil)
  
  lu.assertEquals(module.parse(
    [[
      #{
      bla bla
    ]]), nil)
  
  lu.assertEquals(module.parse(wrapWithEntrypoint'#{##}')[1].block, {tag = 'emptyStatement'})
  
  lu.assertEquals(module.parse(wrapWithEntrypoint'#{#{#}')[1].block, {tag = 'emptyStatement'})
  
  lu.assertEquals(module.parse(wrapWithEntrypoint
    [[
      #{
      x=1
      #}
    ]])[1].block, {tag = 'emptyStatement'})
  
  lu.assertEquals(self:fullTest(
    [[
      #{#}x=1;
      return x
    ]], true), 1)
    
  lu.assertEquals(self:fullTest(
    [[
      #{#} x=10; #{#}
      return x
    ]], true), 10)
  lu.assertEquals(self:fullTest(
        [[
        ##{
        x=10
        #}
        ]], true), 0)
end

function module:testNot()
    local input = 'return ! (1.5~=0)'
    lu.assertEquals(self:fullTest(input, true), false)
  
    input = 'return ! ! (167~=0)'
    lu.assertEquals(self:fullTest(input, true), true)
    
    input = 'return!!!(12412.435~=0)'
    lu.assertEquals(self:fullTest(input, true), false)
end

function module:testIf()
local input = [[
a = 10 + 4;
b = a * a - -10;
c = a/b;
if c < a {
  this is a long name = 24;
  c = 12;
};
return c;
]]
    lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testIfElseElseIf()
  local ifOnlyYes =
[[a = 20;
b = 10;
if b < a {
  b = 1
};
return b;
]]

  lu.assertEquals(self:fullTest(ifOnlyYes, true), 1)

  local ifOnlyNo =
[[a = 20;
b = 100;
if b < a {
  b = 1
};
return b;
]]

  lu.assertEquals(self:fullTest(ifOnlyNo, true), 100)

  local ifElseYes =
[[a = 20;
b = 10;
if b < a {
  b = 1
} else {
  b = 2
};
return b;
]]

  lu.assertEquals(self:fullTest(ifElseYes, true), 1)

  local ifElseNo =
[[a = 20;
b = 100;
if b < a {
  b = 1
} else {
  b = 2
};
return b;
]]

  lu.assertEquals(self:fullTest(ifElseNo, true), 2)

  local ifElseIfYes =
[[a = 20;
b = 10;
if b < a {
  b = 1
} elseif b > a {
  b = 2
};
return b;
]]

  lu.assertEquals(self:fullTest(ifElseIfYes, true), 1)

    local ifElseIfNo =
[[a = 20;
b = 100;
if b < a {
  b = 1
} elseif b > a {
  b = 2
};
return b;
]]

  lu.assertEquals(self:fullTest(ifElseIfNo, true), 2)

  local ifElseIfNeither =
[[a = 20;
b = a;
if b < a {
  b = 1
} elseif b > a {
  b = 2
};
return b;
]]

  lu.assertEquals(self:fullTest(ifElseIfNeither, true), 20)
  local firstClause =
[[a = 20;
b = 10;
if b < a {
  b = 1
} elseif b > a {
  b = 2
} else {
  b = 3
};
return b;
]]
  lu.assertEquals(self:fullTest(firstClause, true), 1)

  local secondClause =
[[a = 20;
b = 100;
if b < a {
  b = 1
} elseif b > a {
  b = 2
} else {
  b = 3
};
return b;
]]
  lu.assertEquals(self:fullTest(secondClause, true), 2)
  local thirdClause =
[[a = 20;
b = a;
if b < a {
b = 1
} elseif b > a {
b = 2
} else {
b = 3
};
return b;
]]

  lu.assertEquals(self:fullTest(thirdClause, true), 3)

  local empty =
[[a = 20;
b = a;
if b < a {
} elseif b > a {
} else {
};
return b;
]]

  lu.assertEquals(self:fullTest(empty, true), 20)
end

function module:testShortCircuit()
  local shortCircuit = [[
a = 20;
b = 10;
if b > a & 1/2 = 0.5 {
  b = 100
};
return b
]]

  local ast = module.parse(wrapWithEntrypoint(shortCircuit))
  local code = module.toStackVM.translate(ast)
  local trace = {}
  local result = module.interpreter.run(code, trace)
  local divide = false
  for i, v in ipairs(trace) do
    if v:gmatch('divide')() then
      divide = true
    end
  end
  lu.assertEquals(divide, false)
  lu.assertEquals(result, 10)

  local shortCircuit2 = [[
a = 20;
b = 10;
if b < a | 1/2 = 0.5 {
  b = 100
};
return b
]]

  ast = module.parse(wrapWithEntrypoint(shortCircuit2))
  code = module.toStackVM.translate(ast)
  trace = {}
  result = module.interpreter.run(code, trace)
  divide = false
  for i, v in ipairs(trace) do
    if v:gmatch('divide')() then
      divide = true
    end
  end
  lu.assertEquals(divide, false)
  lu.assertEquals(result, 100)
end

function module:testWhile()
  local input =
[[function entry point() {
  a = 1;
  b = 10;
  while a < b {
    a = a + 1
  };
  
  return a
}
]]
  lu.assertEquals(self:fullTest(input), 10)
end

function module:testArrays()
  local input =
[[function entry point() {
  array = new[2][2] true;
  array[1][1] = false;

  test = true;
  test = test & array[1][2];
  test = test & array[2][1];
  test = test & array[2][2];
  
  return test
}
]]
  lu.assertEquals(self:fullTest(input), true)
end

function module:testEntryPointNameExclude()
  local input =
[[function entry point() {
  entry point = 12
}
]]
  lu.assertEquals(self:fullTest(input), 'Translation failed!')
end


return module