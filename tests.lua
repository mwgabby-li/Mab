-- Mab Frontend Test Suite (AST generation)
local lu = require 'External.luaunit'
local module = {}
local entryPointName = require('literals').entryPointName
local common = require 'common'

local identifier = common.testGrammar(require 'identifier')
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
  return entryPointName .. ':  -> number '.. ' {' .. string .. '}'
end

function module:fullTest(input, addEntryPoint)
  local errorReporter, ast, code, result

  input = addEntryPoint and wrapWithEntrypoint(input) or input
  errorReporter, ast = module.parse(input)
  if ast == false then
    return 'Parsing failed!'
  end

  errorReporter = module.typeChecker.check(ast)
  if errorReporter:count() > 0 then
    return 'Type checking failed!'
  end
  
  errorReporter, code = module.toStackVM.translate(ast)
  if code == false or errorReporter:count() > 0 then
    return 'Translation failed!'
  end
  errorReporter, result = module.interpreter.execute(code)
  if errorReporter:count() > 0 then
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
  lu.assertEquals(self:fullTest('i: (1 + 2) * 3; return i', true), 9)
end

function module:testReturn()
  lu.assertEquals(self:fullTest('return 1 + 2', true), 3)
end

function module:testAssignmentAndReturn()
  local input = 'i: 4 * 3; return i;'
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
  local input = 'i: - - - - 4 * 3; return i'
  lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testUnaryOperators()
  local input = 'i: -4 * 3; return i'
  lu.assertEquals(self:fullTest(input, true), -12)
end

function module:testEmptyStatementsLeadingTrailing()
    local input = ';;;;i: 4 * 3; return 12;;;;'
  lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testEmptyStatementsInterspersed()
  local input = ';;;;i: 4 * 3;;;;b: 12;;;;return i;;;;'
  lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testComplexSequenceResult()
    local input = 'x value: 12 / 2;'..
                  'y value: 12 * 12 / 2;'..
                  'z value: x value * y value % 12;'..
                  'z value = y value ^ x value + z value;'..
                  'return z value;'
  lu.assertEquals(self:fullTest(input, true), 139314069504)
end

function module:testExponentPrecedence()
    local input = 'i: 2 ^ 3 ^ 2; return i'
  lu.assertEquals(self:fullTest(input, true), 512)
end

function module:testBlockAndLineComments()
  local input =
[[
# Start comment

a: 10 + 4; # End of line comment
#{#} # Single-line block comment

# Block comment inside line comment: #{ blah blah blah #}

#{
# Comments nested in block comment
# Another one
b: b * 10 # Commented-out line of code
#}
b: a * a;
c: a/b;

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
  local errorReporter, result = module.parse(wrapWithEntrypoint'return1')
  lu.assertEquals(result, false)
  errorReporter, result = module.parse(wrapWithEntrypoint':a = 1; returna')
  lu.assertEquals(result, false)
  errorReporter, result = module.parse(wrapWithEntrypoint'return = 1')
  lu.assertEquals(result, false)
  errorReporter, result = module.parse(wrapWithEntrypoint'return return')
  lu.assertEquals(result, false)
  
  lu.assertEquals(self:fullTest('delta x: = 1; return delta x', true), 1)
  
  lu.assertEquals(self:fullTest('return of the variable: 1; return return of the variable', true), 1)
end

function module:testFullProgram()
  local input =
[[
# a is 14
a: 10 + 4;
#{
  14 * 14 - 10 = 186
#}
b: a * a - 10;
# (186 + 10)/14
c: (b + 10)/a;
return c;
]]
  lu.assertEquals(self:fullTest(input, true), 14)
end

function module:testLessonFourEdgeCases()
  local errorReporter, ast, code, result

  errorReporter, ast = module.parse(wrapWithEntrypoint('returned: 10; return returned'))
  errorReporter, code = module.toStackVM.translate(ast)
  lu.assertNotEquals(code, nil)
  errorReporter, result = module.interpreter.execute(code)
  lu.assertEquals(result, 10)

  errorReporter, result = module.parse(
    [[
      :x=1;
      returnx
    ]])
  lu.assertEquals(result, false)
  errorReporter, result = module.parse(
    [[
      #{
      bla bla
    ]])
  lu.assertEquals(result, false)
  errorReporter, result = module.parse(wrapWithEntrypoint'#{##}')
  lu.assertEquals(result[1].assignment.body, {tag = 'emptyStatement'})

  errorReporter, result = module.parse(wrapWithEntrypoint'#{#{#}')
  lu.assertEquals(result[1].assignment.body, {tag = 'emptyStatement'})

  errorReporter, result = module.parse(wrapWithEntrypoint[[
      #{
      :x=1
      #}
    ]])
  lu.assertEquals(result[1].assignment.body, {tag = 'emptyStatement'})
  
  lu.assertEquals(self:fullTest(
    [[
      #{#}x:1;
      return x
    ]], true), 1)
    
  lu.assertEquals(self:fullTest(
    [[
      #{#} x:10; #{#}
      return x
    ]], true), 10)
  lu.assertEquals(self:fullTest(
        [[
        ##{
        x:10
        #}
        ]], true), 0)
end

function module:testNot()
    local input = entryPointName .. ': () -> number' .. ' { if ! (1.5~=0) { return 1 } else { return 0 } }'
    lu.assertEquals(self:fullTest(input), 0)
  
    input = entryPointName .. ': () -> number' .. ' { if ! ! (167~=0){ return 1} else { return 0 } }'
    lu.assertEquals(self:fullTest(input), 1)
    
    input = entryPointName .. ': () -> number' .. ' { if!!!(12412.435~=0) { return 1 } else { return 0 }}'
    lu.assertEquals(self:fullTest(input), 0)
end

function module:testIf()
local input =
[[a: 10 + 4;
b: a * a - -10;
c: a/b;
if c < a {
  this is a long name: 24;
  c = 12;
};
return c;
]]
    lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testIfElseElseIf()
  local ifOnlyYes =
[[a: = 20;
b: 10;
if b < a {
  b = 1
};
return b;
]]

  lu.assertEquals(self:fullTest(ifOnlyYes, true), 1)

  local ifOnlyNo =
[[a: = 20;
b: = 100;
if b < a {
  b = 1
};
return b;
]]

  lu.assertEquals(self:fullTest(ifOnlyNo, true), 100)

  local ifElseYes =
[[a: 20;
b: 10;
if b < a {
  b = 1
} else {
  b = 2
};
return b;
]]

  lu.assertEquals(self:fullTest(ifElseYes, true), 1)

  local ifElseNo =
[[a: 20;
b: 100;
if b < a {
  b = 1
} else {
  b = 2
};
return b;
]]

  lu.assertEquals(self:fullTest(ifElseNo, true), 2)

  local ifElseIfYes =
[[a: 20;
b: 10;
if b < a {
  b = 1
} elseif b > a {
  b = 2
};
return b;
]]

  lu.assertEquals(self:fullTest(ifElseIfYes, true), 1)

    local ifElseIfNo =
[[a: 20;
b: 100;
if b < a {
  b = 1
} elseif b > a {
  b = 2
};
return b;
]]

  lu.assertEquals(self:fullTest(ifElseIfNo, true), 2)

  local ifElseIfNeither =
[[a: 20;
b: a;
if b < a {
  b = 1
} elseif b > a {
  b = 2
};
return b;
]]

  lu.assertEquals(self:fullTest(ifElseIfNeither, true), 20)
  local firstClause =
[[a: 20;
b: 10;
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
[[a: 20;
b: 100;
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
[[a: 20;
b: a;
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
[[a: 20;
b: a;
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
a: 20;
b: 10;
if b > a & 1/2 = 0.5 {
  b = 100
};
return b
]]

  local ast, code, result, errorReporter
  errorReporter, ast = module.parse(wrapWithEntrypoint(shortCircuit))
  errorReporter, code = module.toStackVM.translate(ast)
  lu.assertNotEquals(code, nil)
  local parameters = {show ={trace = true}}
  errorReporter, result, trace = module.interpreter.execute(code, parameters)
  local divide = false
  for _, v in ipairs(trace) do
    if v:gmatch('divide')() then
      divide = true
    end
  end
  lu.assertEquals(divide, false)
  lu.assertEquals(result, 10)

  local shortCircuit2 = [[
a: 20;
b: 10;
if b < a | 1/2 = 0.5 {
  b = 100
};
return b
]]

  errorReporter, ast = module.parse(wrapWithEntrypoint(shortCircuit2))
  errorReporter, code = module.toStackVM.translate(ast)
  errorReporter, result, trace = module.interpreter.execute(code, parameters)
  divide = false
  for _, v in ipairs(trace) do
    if v:gmatch('divide')() then
      divide = true
    end
  end
  lu.assertEquals(divide, false)
  lu.assertEquals(result, 100)
end

function module:testWhile()
  local input =
[[entry point: () -> number {
  a: 1;
  b: 10;
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
[[entry point: () -> number {
  array: new[2][2] true;
  array[1][1] = false;

  test: true;
  test = test & array[1][2];
  test = test & array[2][1];
  test = test & array[2][2];
  
  if test {
    return 1
  } else {
    return 0
  }
}
]]
  lu.assertEquals(self:fullTest(input), 1)
end

function module:testArrayNonNumeralIndexing()
  local input =
[[entry point: () -> number {
  array: new[2][2 + 2] true;
  array[1][1] = false;

  subArray: new[2 + 2] true;
  
  array[1] = subArray;

  test: true;
  test = test & array[1][2];
  test = test & array[2][1];
  test = test & array[2][2];
  
  if test {
    return 1
  } else {
    return 0
  }
}
]]

  lu.assertEquals(self:fullTest(input), 'Type checking failed!')
end

function module:testPassingAndReturningArrays()
  local input =
[[test11: (n:[2][2] boolean) -> boolean {
  return n[1][1]
};

testReturnArray: () -> [2][2] boolean {
  array: new[2][2] true;
  array[1][1] = true;
  return array
};

entry point: () -> number {
  array: new[2][2] true;
  #array[1][1] = false;
  result: = test11(testReturnArray());

  if result = true {
    return 1
  } else {
    return 0
  }
}
]]

  lu.assertEquals(self:fullTest(input), 1)

  input =
[[test11: (n:[2][2] boolean) -> boolean {
  return n[1][1]
};

testReturnArray: () -> [2][2] boolean {
  array: new[2][2] true;
  array[1][1] = false;
  return array
};

entry point: () -> number {
  array: new[2][2] true;
  #array[1][1] = false;
  result: test11(testReturnArray());

  if result = true {
    return 1
  } else {
    return 0
  }
}
]]

  lu.assertEquals(self:fullTest(input), 0)
end

function module:testFunctionCall()
  local input =
[[
another function: () -> number {
  return 12
};

entry point: () -> number {
  return 24 + another function();
}
]]

  lu.assertEquals(self:fullTest(input), 36)
end

function module:testDuplicateFunctions()
  local input =
[[another function: () -> number {
  return 33
};

another function: () -> number {
  return 42
};

entry point: () -> number {
  a: 1;
  
  a = 23 + another function();
  return a
};

another function: () -> number {
  return 3
}
]]

  local errorReporter, ast = module.parse(input)
  lu.assertEquals(type(ast), 'table')
  
  local code
  errorReporter, code = module.toStackVM.translate(ast, errorReporter)
  lu.assertEquals(errorReporter:count(), 4)
  
  input =
[[another function: () -> number {
  return 33
};

another function: () -> number {
  return 42
};

entry point: () -> number {
  a: 1;
  
  a = 23 + another function();
  return a
};
entry point: () -> number {
};


another function: () -> number {
  return 3
}
]]
  errorReporter, ast = module.parse(input)
  lu.assertEquals(type(ast), 'table')
  
  errorReporter, code = module.toStackVM.translate(ast, errorReporter)
  lu.assertEquals(errorReporter:count(), 7)
end

function module:testIndirectRecursion()
  local input =
[[entry point: () -> number {
  n:global = 10;
  if even() = true {
    return 1
  } else {
    return 0
  }
};
even: () -> boolean {
  if n ~= 0 {
    n = n - 1;
    return odd()
  } else {
    return true
  }
};
odd: () -> boolean {
  if n ~= 0 {
    n = n - 1;
    return even()
  } else {
    return false
  }
}
]]


  lu.assertEquals(self:fullTest(input), 1)

  input =
[[
entry point: () -> number {
  n:global = 11;
  if even() = true {
    return 1
  } else {
    return 0
  }
};
even: () -> boolean {
  if n ~= 0 {
    n = n - 1;
    return odd()
  } else {
    return true
  }
};
odd: () -> boolean {
  if n ~= 0 {
    n = n - 1;
    return even()
  } else {
    return false
  }
}
]]
  lu.assertEquals(self:fullTest(input), 0)
  
input =
[[
entry point: () -> number {
  n:global = 10;
  if odd() = true {
    return 1
  } else {
    return 0
  }
};
even: () -> boolean {
  if n ~= 0 {
    n = n - 1;
    return odd()
  } else {
    return true
  }
};
odd: () -> boolean {
  if n ~= 0 {
    n = n - 1;
    return even()
  } else {
    return false
  }
}
]]


  lu.assertEquals(self:fullTest(input), 0)

  input =
[[
entry point: () -> number {
  n:global = 11;
  if odd() = true {
    return 1
  } else {
    return 0
  }
};
even: () -> boolean {
  if n ~= 0 {
    n = n - 1;
    return odd()
  } else {
    return true
  }
};
odd: () -> boolean {
  if n ~= 0 {
    n = n - 1;
    return even()
  } else {
    return false
  }
}
]]
  lu.assertEquals(self:fullTest(input), 1)
end

-- test local variables
function module:testLocalVariableCreation()
  local input =
[[entry point: () -> number {
  x:number = 1;
  y:number = 2;
  
  return 10
}
]]

  lu.assertEquals(self:fullTest(input), 10)
end

function module:testDefaultValueForLocalVariables()
  local input =
[[entry point: () -> number {
  x:number = 10;
  y:number;
  
  return y + x
}
]]

  lu.assertEquals(self:fullTest(input), 10)
end

function module:testMixingGlobalsAndLocals()
  local input =
[[helper: () -> number {
  return 10
};

entry point: () -> number {
  x:number = 10;
  y:number;
  
  z:global number = 12;

  return 1 + helper() + z
}
]]

  lu.assertEquals(self:fullTest(input), 23)
end

-- test local variable usage
function module:testLocalVariableUsage()
  local input =
[[entry point: () -> number {
  x:number = 10;
  y:number = 20;
  {
    x:number = 30;
    y = x + 3;
  };
  return y
}
]]

  lu.assertEquals(self:fullTest(input), 33)
end

function module:testLocalVariableShadowingAndNameCollision()
  local input =
[[entry point: () -> number {
    x: 10;
    y: 20;
    {
      y: 30;
      y = x + 3;
    };
    return y
}
]]

  lu.assertEquals(self:fullTest(input), 20)
  
input =
[[entry point: () -> number {
    x: 10;
    y: 20;
    {
      y: 30;
      y = y + 3;
      return y
    };
}
]]

  lu.assertEquals(self:fullTest(input), 33)
  
input =
[[entry point: () -> number {
    x: 10;
    x: 11;
    y: 20;
    {
      y: 30;
      y: 10;
      y = y + 3;
      return y
    };
}
]]
  local _, ast = module.parse(input)
  lu.assertNotEquals(ast, nil)

  local errorReporter, _ = module.toStackVM.translate(ast)
  lu.assertEquals(errorReporter:count(), 2)
end

function module:testWrongFunctionArgumentTypes()
  local input =
[[test: (n:number) -> number {
  return n
};
entry point: -> number {
  call test(true)
}
]]

  lu.assertEquals(self:fullTest(input), 'Type checking failed!')
end

-- test function parameter count mismatch (zero when should be something, number when should be another number, something when should be zero.)
function module:testParameterArgumentCountMismatch()
  -- Matching
  local input =
[[test: (n:number) -> number {
  return n
};

entry point: () -> number {
  return test(2)
}
]]

  lu.assertEquals(self:fullTest(input), 2)

  -- Sent nothing, should be sent one
  input =
[[test: (n:number) -> number {
  return n
};

entry point: () -> number {
  return test()
}
]]

  lu.assertEquals(self:fullTest(input), 'Translation failed!')

  -- Sent one, should have sent two
  input =
[[test: (n:number n2:number) -> number {
  return n
};

entry point: () -> number {
  return test(2)
}
]]

  lu.assertEquals(self:fullTest(input), 'Translation failed!')
  
  -- Sent one, should not have sent any
  input =
[[test: () -> number {
};

entry point: () -> number {
  return test(2)
}
]]

  lu.assertEquals(self:fullTest(input), 'Translation failed!')
end

function module:testDuplicateFunctionParameters()
  local input = 
[[manyCollisions: (n:number n:number g:number g:number g:number b:number) -> number
   {
};

entry point: () -> number {
  return manyCollisions(1, 1, 2, 2, 2, 3)
}
]]

  lu.assertEquals(self:fullTest(input), 'Translation failed!')
end

function module:testFactorial()
  local input =
[[factorial: (n:number)-> number {
  if n <= 0 {
    return 1
  };
  
  return n * factorial(n - 1)
};

entry point: () -> number {
  return factorial(10)
}
]]
  
  lu.assertEquals(self:fullTest(input), 3628800)
end


function module:testMainNoParameters()
  local input =
[[
entry point: (n:number) -> number {
}
]]
  
  lu.assertEquals(self:fullTest(input), 'Translation failed!')
end

function module:testFunctionParameters()
  local input =
[[sum: (a:number b:number) -> number {
  return a + b
};
entry point: () -> number {
  return sum(65,24)
}
]]
  lu.assertEquals(self:fullTest(input), 89)
  
  input = 
[[sum: (a:number b:number) -> number {
  return a + b
};
entry point: () -> number {
  a:number = 10;
  b:number = 24;
  
  return sum(a * 12,b)
}
]]

  lu.assertEquals(self:fullTest(input), 144)
end

function module:testTernaryOperator()
  local input =
[[entry point: () -> number {

    x: 12;
    y: 10;

    result: x > y ? true : false;

    if result = true {
        return 1
    } else {
        return 0
    }
}
]]
  lu.assertEquals(self:fullTest(input), 1)

  input =
  [[entry point: () -> number {

      x: 10;
      y: 12;

      result: x > y ? true : false;

      if result = true {
          return 1
      } else {
          return 0
      }
  }
  ]]

  lu.assertEquals(self:fullTest(input), 0)
  
  -- Not a boolean
  input =
  [[entry point: () -> number {

      x: 10;
      y: 12;

      result: x + y ? true : false;

      if result = true {
          return 1
      } else {
          return 0
      }
  }
  ]]

  lu.assertEquals(self:fullTest(input), 'Type checking failed!')

  -- Mismatched types in branches
  input =
  [[entry point: () -> number {

      x: 10;
      y: 12;

      result: x < y ? true : 0;

      if result = true {
          return 1
      } else {
          return 0
      }
  }
  ]]

  lu.assertEquals(self:fullTest(input), 'Type checking failed!')
end

-- test default argument
function module:testExampleProgram()
  local input =
  [[global container: -> {
      g:global = 12
  };

  factorial: (n:number) -> number {
      if n = 0 {
          return 1
      } else {
          return n * factorial(n - 1)
      }
  };

  sum: (a:number b:number) -> number = {
      return a + b
  };

  # Commas can be included:
  div: (a:number, b:number) -> number {
      return a / b
  };

  # This could also be written as " entry point: -> number ."
  entry point: () -> number {
      call global container();

      # Fully specified variable
      a:local number = 2;
      # Equals is optional...
      b:= 2;
      # Other than the name, the same as the two previous.
      c: 2;

      return factorial( div( sum( a, b ) * c, 2) )
  }
  ]]

  lu.assertEquals(self:fullTest(input), 24.0);
end

function module:testDefaultArguments()
  -- Default with one parameter
  --  Used:
  local input =
  [[default arguments: (n:number = 12 * 17) -> number {
    return n
  };

  entry point: -> number {
    return default arguments();
  }
  ]]

  lu.assertEquals(self:fullTest(input), 12 * 17)
  --  Not used:
  input =
  [[default arguments: (n:number = 12 * 17) -> number {
    return n
  };

  entry point: -> number {
    return default arguments(12);
  }
  ]]
  lu.assertEquals(self:fullTest(input), 12)

  -- Default with multiple parameters:
  --  Used:
  input =
  [[default arguments: (b:boolean n:number = 12 * 17) -> number {
    return n
  };

  entry point: -> number {
    return default arguments(true);
  }
  ]]
  lu.assertEquals(self:fullTest(input), 12 * 17)

  --  Not used:
  input =
  [[default arguments: (b:boolean n:number = 12 * 17) -> number {
    return n
  };

  entry point: -> number {
    return default arguments(true, 12);
  }
  ]]
  lu.assertEquals(self:fullTest(input), 12)
end

function module:testMismatchedFunctionAssignments()
  -- Mismatched parameter types
  local input =
  [[test: (b:boolean n:number) -> number {
  };

  test2: -> number {
  };

  entry point: -> number {
    test = test2
  }
  ]]
  lu.assertEquals(self:fullTest(input), 'Type checking failed!')

  -- Mismatched result types
  input =
  [[test: (b:boolean n:number) -> number {
  };

  test2: -> boolean {
  };

  entry point: -> number {
    test = test2
  }
  ]]
  lu.assertEquals(self:fullTest(input), 'Type checking failed!')


  -- Mismatched parameter types with multiple parameters
  input =
  [[
testMismatches:           (b:boolean, n:number, func: (n:number) ->) -> number {
};

testMismatchedParameter:  (b:boolean, n:boolean, func: (n:number) ->) -> number {
};

testMismatchedResultType: (b:boolean, n:number, func: (n:number) ->) -> boolean {
};

entry point: -> number {
  testMismatches = testMismatchedParameter
}
  ]]
  lu.assertEquals(self:fullTest(input), 'Type checking failed!')

  input =
  [[
testMismatches:           (b:boolean, n:number, func: (n:number) ->) -> number {
};

testMismatchedParameter:  (b:boolean, n:boolean, func: (n:number) ->) -> number {
};

testMismatchedResultType: (b:boolean, n:number, func: (n:number) ->) -> boolean {
};

entry point: -> number {
  testMismatches = testMismatchedResultType
}
  ]]
  lu.assertEquals(self:fullTest(input), 'Type checking failed!')
end


-- Test function within another function
function module:testFunctionWithinFunction()
  local input =
  [[entry point: -> number {
    a local function: -> number {
      return 33
    };

    return a local function();
  }
  ]]

  lu.assertEquals(self:fullTest(input), 33)
end

-- Test function assignment
function module:testFunctionAssignment()
  local input =
  [[test: -> number {
    return 33
  };

  entry point: -> number {
    test2: -> number = test;

    return test2();
  }
  ]]

  lu.assertEquals(self:fullTest(input), 33)

  -- Test function assignment of existing function
  input =
  [[test return anything: -> number {};

test return 10: -> number {
  return 10;
};

entry point: -> number {
  test return anything = test return 10;

  return test return anything()
}]]

  lu.assertEquals(self:fullTest(input), 10)
end

function module:testArrayFunctionCallAndAssignment()
  local input =
[[to number: -> number {
  return 33;
};

to 12: -> number {
  return 12;
};

entry point: -> number {

    array: new[10][2] to number;
    
    i: 1;
    while i <= 10 {
      array[i][1] = to 12;
    
      i = i + 1;
    };
    
    sum: 0;
    
    i = 1;
    while i <= 10 {
      j: 1;
      while j <= 2 {
        sum = sum + array[i][j]();
        j = j + 1;
      };
      i = i + 1;
    };
    
  return sum;
}]]

  lu.assertEquals(self:fullTest(input), 450)
end

function module:testBasicStringSupport()
  local input =
[[entry point: -> number {
    a string: 'a string "this is single quoted" and the end';
    a string = 'a string ''this is double quoted'' and the end';
a string = 'this is a multiline
string using the same basic syntax, and you can insert single quotes as ''"'' or double quotes as '''''' ';

a unicode string: 'This is a string in UTF-8: ''いづれの御時にか、女御、更衣あまたさぶらひたまひけるなかに、いとやむごとなき際にはあらぬが、すぐれて時めきたまふありけり。''';

a string = a unicode string;
}]]

  lu.assertEquals(self:fullTest(input), 0)
end

function module:testComplexFirstClassFunctions()
  local input =
[[
test return 10: -> number {
  return 10;
};
test return 20: -> number {
  return 10;
};

testReturnLocalFunction: -> -> number {
  a local function: -> number {
    a: 33;
    {
      b: 22;
      a = a + b;
    };
    return a
  };
  
  return a local function;
};

entry point: -> number {
  test return anything: 10 > 20 ? test return 10 : test return 20;

  a local function: -> number {
    return 33
  };
  
  lf: testReturnLocalFunction();
  
  return lf();
}
]]

  lu.assertEquals(self:fullTest(input), 55)

  input =
[[test return 10: -> number {
  return 10;
};
test return 20: -> number {
  return 10;
};

testReturnLocalFunction: -> -> number {
  internal local function: -> number {
    a: 33;
    {
      b: 22;
      a = a + b;
    };
    return a
  };
  
  return internal local function;
};


entry point: -> number {
  test return anything: 10 > 20 ? test return 10 : test return 20;

  a local function: -> number {
    a: 33;
    {
      b: 22;
      a = a + b;
    };
    return a
  };

  call a local function();
  
  lf: testReturnLocalFunction();
  
  return lf();
}
]]
  lu.assertEquals(self:fullTest(input), 55)

end

function module:testOffsetIndexing()
  local input =
[[entry point: -> number {
    a: new [2][2] 3;
    a+[0][0] = 0;
    a+[0][1] = 1;
    a+[1][0] = 10;
    a+[1][1] = 11;

    return a+[0][0] + a+[0][1] + a+[1][0] + a+[1][1];
}
]]

  lu.assertEquals(self:fullTest(input), 22)

  -- Test with an array with different sizes in each dimension:
  input =
[[entry point: -> number {
    a: new [2][3] 3;
    a+[0][0] = 0;
    a+[0][1] = 1;
    a+[0][2] = 2;
    a+[1][0] = 10;
    a+[1][1] = 11;
    a+[1][2] = 12;

    return a+[0][0] + a+[0][1] + a+[0][2] + a+[1][0] + a+[1][1] + a+[1][2];
}
]]

  lu.assertEquals(self:fullTest(input), 36)
end

-- Aspirational. The issue is that expressions can't contain blocks.
-- Basically, this is a test of lambdas.
--function module:testCreateFunctionWithTernaryExpressionBodies()
--  local input =
--[[entry point: -> number {
--  returning parameter: (n:number) -> number = true ? { a: n; b: n; return b; } : { b: n; return -b; };
--
--  c:10;
--
--  return returning parameter(12);
--}
--]]
--
--  lu.assertEquals(self:fullTest(input), 12)
--end
--
return module