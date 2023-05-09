-- Mab Frontend Test Suite (AST generation)
local lu = require 'External.luaunit'
-- Most recent supported version
local astVersion = 1
local module = {}
local entryPointName = require('literals').entryPointName

local identifier = require('common').testGrammar(require 'identifier')
function module:testIdentifiers()
    lu.assertEquals(identifier:match('_leading_underscore'), '_leading_underscore')
    lu.assertEquals(identifier:match('this has spaces '), 'this has spaces')
    lu.assertEquals(identifier:match('0this is not valid'), nil)
end

local numeral = require('common').testGrammar(require 'numeral')

function module:testNaturalNumbers()
    lu.assertEquals(numeral:match('0'), 0)
    lu.assertEquals(numeral:match('100'), 100)
    lu.assertEquals(numeral:match('1 000'), 1000)
    lu.assertEquals(numeral:match('1 000'), 1000)
    lu.assertEquals(numeral:match('1 2 3 4 5 6 7 8 9 0'), 1234567890)
end

function module:testRationalNumbers()
    lu.assertEquals(numeral:match('0.'), 0)
    lu.assertEquals(numeral:match('0.0'), 0)
    lu.assertEquals(numeral:match('0.1'), 0.1)
    lu.assertEquals(numeral:match('0.01'), 0.01)
    lu.assertEquals(numeral:match('.1'), 0.1)
    lu.assertEquals(numeral:match('.01'), 0.01)
    lu.assertEquals(numeral:match('1.'), 1)
    lu.assertEquals(numeral:match('10.'), 10)
end

function module:testExponents()
    lu.assertEquals(numeral:match('1e0'), 1)
    lu.assertEquals(numeral:match('1e1'), 10)
    lu.assertEquals(numeral:match('1e2'), 100)
    lu.assertEquals(numeral:match('1e+0'), 1)
    lu.assertEquals(numeral:match('1e+1'), 10)
    lu.assertEquals(numeral:match('1e+2'), 100)
    lu.assertEquals(numeral:match('1e-1'), 0.1)
    lu.assertEquals(numeral:match('1e-2'), 0.01)
    lu.assertEquals(numeral:match('1e-3'), 0.001)
end

function module:testRationalExponents()
    lu.assertEquals(numeral:match('1.01e0'), 1.01)
    lu.assertEquals(numeral:match('1.02e1'), 10.2)
    lu.assertEquals(numeral:match('1.03e2'), 103)
    lu.assertEquals(numeral:match('1.04e+0'), 1.04)
    lu.assertEquals(numeral:match('1.05e+1'), 10.5)
    lu.assertEquals(numeral:match('1.06e+2'), 106)
    lu.assertEquals(numeral:match('1.07e-1'), 0.107)
    lu.assertEquals(numeral:match('1.08e-2'), 0.0108)
    lu.assertEquals(numeral:match('1.09e-3'), 0.00109)
end

--[[
function module:testTrailingBaseNumbers()
    lu.assertEquals(numeral:match('11 b1'), 4)
    lu.assertEquals(numeral:match('1001 b2'), 15)
    lu.assertEquals(numeral:match('1221 b3'), 63)
    -- Test random digits in random bases
    lu.assertEquals(numeral:match('0ADF4 b16'), 44756)

end
]]

function module:testBaseNumber()
    lu.assertEquals(numeral:match('01 0'), 0)
    lu.assertEquals(numeral:match('01 1'), 1)
    lu.assertEquals(numeral:match('01 10'), 2)
    lu.assertEquals(numeral:match('01 11'), 3)
    lu.assertEquals(numeral:match('01 100'), 4)
    lu.assertEquals(numeral:match('01 101'), 5)
    lu.assertEquals(numeral:match('01 110'), 6)
    lu.assertEquals(numeral:match('01 111'), 7)
    lu.assertEquals(numeral:match('01 1000'), 8)
    lu.assertEquals(numeral:match('01 1001'), 9)
    lu.assertEquals(numeral:match('01 1010'), 10)
    lu.assertEquals(numeral:match('01 1011'), 11)
    lu.assertEquals(numeral:match('01 1100'), 12)
    lu.assertEquals(numeral:match('01 1101'), 13)
    lu.assertEquals(numeral:match('01 1110'), 14)
    lu.assertEquals(numeral:match('01 1111'), 15)
    lu.assertEquals(numeral:match('01 10000'), 16)
    lu.assertEquals(numeral:match('01 10001'), 17)
    lu.assertEquals(numeral:match('01 10010'), 18)
    lu.assertEquals(numeral:match('01 10011'), 19)
    lu.assertEquals(numeral:match('01 10100'), 20)
    lu.assertEquals(numeral:match('01 10101'), 21)
    lu.assertEquals(numeral:match('01 10110'), 22)
    lu.assertEquals(numeral:match('01 10111'), 23)
    lu.assertEquals(numeral:match('01 11000'), 24)
    lu.assertEquals(numeral:match('01 11001'), 25)
    lu.assertEquals(numeral:match('01 11010'), 26)
    lu.assertEquals(numeral:match('01 11011'), 27)
    lu.assertEquals(numeral:match('01 11100'), 28)
    lu.assertEquals(numeral:match('01 11101'), 29)
    lu.assertEquals(numeral:match('01 11110'), 30)
end

function module:testBaseTwelveNumbers()
    lu.assertEquals(numeral:match('0B 0'), 0)
    lu.assertEquals(numeral:match('0B 1'), 1)
    lu.assertEquals(numeral:match('0B 2'), 2)
    lu.assertEquals(numeral:match('0B 3'), 3)
    lu.assertEquals(numeral:match('0B 4'), 4)
    lu.assertEquals(numeral:match('0B 5'), 5)
    lu.assertEquals(numeral:match('0B 6'), 6)
    lu.assertEquals(numeral:match('0B 7'), 7)
    lu.assertEquals(numeral:match('0B 8'), 8)
    lu.assertEquals(numeral:match('0B 9'), 9)
    lu.assertEquals(numeral:match('0B A'), 10)
    lu.assertEquals(numeral:match('0B B'), 11)
    lu.assertEquals(numeral:match('0B 10'), 12)
    lu.assertEquals(numeral:match('0B 11'), 13)
    lu.assertEquals(numeral:match('0B 12'), 14)
    lu.assertEquals(numeral:match('0B 13'), 15)
    lu.assertEquals(numeral:match('0B 14'), 16)
    lu.assertEquals(numeral:match('0B 15'), 17)
    lu.assertEquals(numeral:match('0B 16'), 18)
    lu.assertEquals(numeral:match('0B 17'), 19)
    lu.assertEquals(numeral:match('0B 18'), 20)
    lu.assertEquals(numeral:match('0B 19'), 21)
    lu.assertEquals(numeral:match('0B 1A'), 22)
    lu.assertEquals(numeral:match('0B 1B'), 23)
    lu.assertEquals(numeral:match('0B 20'), 24)
end

function module:testUnaryNumbers()
    lu.assertEquals(numeral:match('00 1'), 1)
    lu.assertEquals(numeral:match('00 11'), 2)
    lu.assertEquals(numeral:match('00 111'), 3)
    lu.assertEquals(numeral:match('00 1111'), 4)
    lu.assertEquals(numeral:match('00 11111'), 5)
    lu.assertEquals(numeral:match('00 11111 1'), 6)
    lu.assertEquals(numeral:match('00 11111 11'), 7)
    lu.assertEquals(numeral:match('00 11111 111'), 8)
end


local function wrapWithEntrypoint(string)
  return 'function -> number: '.. entryPointName ..' {' .. string .. '}'
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
  local result, errors = module.interpreter.execute(code)
  if #errors ~= 0 then
    return 'Running failed!'
  end  
  return result
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
  lu.assertNotEquals(code, nil)
  local result = module.interpreter.execute(code)
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
  
  lu.assertEquals(module.parse(wrapWithEntrypoint'#{##}')[1].block.body, {tag = 'emptyStatement'})
  
  lu.assertEquals(module.parse(wrapWithEntrypoint'#{#{#}')[1].block.body, {tag = 'emptyStatement'})
  
  lu.assertEquals(module.parse(wrapWithEntrypoint
    [[
      #{
      x=1
      #}
    ]])[1].block.body, {tag = 'emptyStatement'})
  
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
    local input = 'function -> boolean:' .. entryPointName .. ' { return ! (1.5~=0) }'
    lu.assertEquals(self:fullTest(input), false)
  
    input = 'function -> boolean:' .. entryPointName .. ' { return ! ! (167~=0) }'
    lu.assertEquals(self:fullTest(input), true)
    
    input = 'function -> boolean:' .. entryPointName .. ' { return!!!(12412.435~=0) }'
    lu.assertEquals(self:fullTest(input), false)
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
  lu.assertNotEquals(code, nil)
  local result = module.interpreter.execute(code, trace)
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
  result = module.interpreter.execute(code, trace)
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
[[function -> number: entry point {
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
[[function -> boolean: entry point {
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
[[function -> number: entry point {
  entry point = 12
}
]]
  lu.assertEquals(self:fullTest(input), 'Translation failed!')
end

function module:testFunctionCall()
  local input =
[[
function -> number: another function {
  return 12
}

function -> number: entry point {
  return 24 + another function();
}
]]

  lu.assertEquals(self:fullTest(input), 36)
end

function module:testDuplicateFunctions()
  local input =
[[function -> number: another function {
  return 33
}

function -> number: another function {
  return 42
}

function -> number: entry point {
  a = 1;
  
  a = 23 + another function();
  return a
}

function -> number: another function {
  return 3
}
]]

  local ast = module.parse(input)
  lu.assertEquals(type(ast), 'table')
  
  local code, errors = module.toStackVM.translate(ast)
  lu.assertEquals(#errors, 4)
  
  input =
[[function -> number: another function {
  return 33
}

function -> number: another function {
  return 42
}

function -> number: entry point {
  a = 1;
  
  a = 23 + another function();
  return a
}
function -> number: entry point {
}


function -> number: another function {
  return 3
}
]]
  ast = module.parse(input)
  lu.assertEquals(type(ast), 'table')
  
  code, errors = module.toStackVM.translate(ast)
  lu.assertEquals(#errors, 7)
end

function module:testIndirectRecursion()
  local input =
[[function -> boolean: entry point {
  n = 10;
  return even()
}
function -> boolean: even {
  if n ~= 0 {
    n = n - 1;
    return odd()
  } else {
    return true
  }
}
function -> boolean: odd {
  if n ~= 0 {
    n = n - 1;
    return even()
  } else {
    return false
  }
}
]]


  lu.assertEquals(self:fullTest(input), true)

  input =
[[
function -> boolean: entry point {
  n = 11;
  return even()
}
function -> boolean: even {
  if n ~= 0 {
    n = n - 1;
    return odd()
  } else {
    return true
  }
}
function -> boolean: odd {
  if n ~= 0 {
    n = n - 1;
    return even()
  } else {
    return false
  }
}
]]
  lu.assertEquals(self:fullTest(input), false)
  
input =
[[
function -> boolean: entry point {
  n = 10;
  return odd()
}
function -> boolean: even {
  if n ~= 0 {
    n = n - 1;
    return odd()
  } else {
    return true
  }
}
function -> boolean: odd {
  if n ~= 0 {
    n = n - 1;
    return even()
  } else {
    return false
  }
}
]]


  lu.assertEquals(self:fullTest(input), false)

  input =
[[
function -> boolean: entry point {
  n = 11;
  return odd()
}
function -> boolean: even {
  if n ~= 0 {
    n = n - 1;
    return odd()
  } else {
    return true
  }
}
function -> boolean: odd {
  if n ~= 0 {
    n = n - 1;
    return even()
  } else {
    return false
  }
}
]]
  lu.assertEquals(self:fullTest(input), true)
end

-- test local variables
function module:testLocalVariableCreation()
  local input =
[[function -> number: entry point {
  number:x = 1;
  number:y = 2;
  
  return 10
}
]]

  lu.assertEquals(self:fullTest(input), 10)
end

function module:testDefaultValueForLocalVariables()
  local input =
[[function -> number: entry point {
  number:x = 10;
  number:y;
  
  return 1
}
]]

  lu.assertEquals(self:fullTest(input), 1)
end

function module:testMixingGlobalsAndLocals()
  local input =
[[function -> number: helper {
  return 10
}

function -> number: entry point {
  number:x = 10;
  number:y;
  
  global number:z = 12;
    
  return 1 + helper() + z
}
]]

  lu.assertEquals(self:fullTest(input), 23)
end

-- test local variable usage
function module:testLocalVariableUsage()
  local input =
[[function -> number: entry point {
  number:x = 10;
  number:y = 20;
  {
    number:x = 30;
    y = x + 3;
  };
  return y
}
]]

  lu.assertEquals(self:fullTest(input), 33)
end

function module:testLocalVariableShadowingAndNameCollision()
  local input =
[[function -> number: entry point {
    :x = 10;
    :y = 20;
    {
      :y = 30;
      y = x + 3;
    };
    return y
}
]]

  lu.assertEquals(self:fullTest(input), 20)
  
input =
[[function -> number: entry point {
    :x = 10;
    :y = 20;
    {
      :y = 30;
      y = y + 3;
      return y
    };
}
]]

  lu.assertEquals(self:fullTest(input), 33)
  
input =
[[function -> number: entry point {
    :x = 10;
    :x = 11;
    :y = 20;
    {
      :y = 30;
      :y = 10;
      y = y + 3;
      return y
    };
}
]]
  local ast = module.parse(input)
  lu.assertNotEquals(ast, nil)
    
  local code, errors = module.toStackVM.translate(ast)
  lu.assertNotEquals(errors, nil)
  lu.assertEquals(#errors, 2)
end

-- test function parameters

-- test local variable/parameter name collision

-- test arguments and parameter semantically?

-- test main has no parameters

-- test default argument

return module