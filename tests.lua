-- Mab Frontend Test Suite (AST generation)
local lu = require 'External.luaunit'
local module = {}
local entryPointName = require('literals').entryPointName
local common = require 'common'

local identifier = common.testGrammar(require 'identifier')
function module:testIdentifiers()
    lu.assertEquals(identifier:match('_leading_underscore'), '_leading_underscore')
    lu.assertEquals(identifier:match('this has spaces '), 'this has spaces')
    lu.assertEquals(identifier:match('0this is valid'), '0this is valid')
    lu.assertEquals(identifier:match('0this is not valid b12'), nil)
end

local numeral = require('common').testGrammar(require('numeral').capture)

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
    lu.assertEquals(numeral:match('1b^0'), 1)
    lu.assertEquals(numeral:match('1b^1'), 10)
    lu.assertEquals(numeral:match('1b^2'), 100)
    lu.assertEquals(numeral:match('1b^+0'), 1)
    lu.assertEquals(numeral:match('1b^+1'), 10)
    lu.assertEquals(numeral:match('1b^+2'), 100)
    lu.assertEquals(numeral:match('1b^-1'), 0.1)
    lu.assertEquals(numeral:match('1b^-2'), 0.01)
    lu.assertEquals(numeral:match('1b^-3'), 0.001)
end

function module:testRationalExponents()
    lu.assertEquals(numeral:match('1.01b^0'), 1.01)
    lu.assertEquals(numeral:match('1.02b^1'), 10.2)
    lu.assertEquals(numeral:match('1.03b^2'), 103)
    lu.assertEquals(numeral:match('1.04b^+0'), 1.04)
    lu.assertEquals(numeral:match('1.05b^+1'), 10.5)
    lu.assertEquals(numeral:match('1.06b^+2'), 106)
    lu.assertEquals(numeral:match('1.07b^-1'), 0.107)
    lu.assertEquals(numeral:match('1.08b^-2'), 0.0108)
    lu.assertEquals(numeral:match('1.09b^-3'), 0.00109)
end

function module:testTrailingBaseNumbers()
    lu.assertEquals(numeral:match('11 b2'), 3)
    lu.assertEquals(numeral:match('1001 b2'), 9)
    lu.assertEquals(numeral:match('1221 b3'), 52)
    -- Test random digits in random bases
    lu.assertEquals(numeral:match('0ADF4 b16'), 44532)

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

  errorReporter, dot = module.toGraphviz.translate(ast)
  if dot == false or errorReporter:count() > 0 then
    return 'Graphviz failed!'
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

function module:init(parse, typeChecker, toGraphviz, toStackVM, interpreter)
    module.parse = parse
    module.typeChecker = typeChecker
    module.toGraphviz = toGraphviz
    module.toStackVM = toStackVM
    module.interpreter = interpreter
    return module
end

function module:testAssignmentAndParentheses()
  lu.assertEquals(self:fullTest('i: (1 + 2) * 3   i -> result', true), 9)
end

function module:testReturn()
  lu.assertEquals(self:fullTest('1 + 2 -> result', true), 3)
end

function module:testAssignmentAndReturn()
  local input = 'i: 4 * 3   i -> result'
  lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testEmptyInput()
  local input = '        '
  lu.assertEquals(self:fullTest(input, true), 0)
  input = ''
  lu.assertEquals(self:fullTest(input, true), 0)
end

function module:testStackedUnaryOperators()
  local input = 'i: - - - - 4 * 3  i -> result'
  lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testUnaryOperators()
  local input = 'i: -4 * 3   i -> result'
  lu.assertEquals(self:fullTest(input, true), -12)
end

function module:testWhitespaceLeadingTrailing()
    local input = '\t        i: 4 * 3  12 -> result        '
  lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testWhitespaceInterspersed()
  local input = '    \t    i: 4 * 3  \t      b: 12     \t   i -> result        '
  lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testComplexSequenceResult()
    local input =
[[
x value: 12 / 2
y value: 12 * 12 / 2
z value: x value * y value % 12
z value <- y value ^ x value + z value
z value -> result]]

  lu.assertEquals(self:fullTest(input, true), 139314069504)
end

function module:testExponentPrecedence()
    local input = 'i: 2 ^ 3 ^ 2   i -> result'
  lu.assertEquals(self:fullTest(input, true), 512)
end

function module:testBlockAndLineComments()
  local input =
[[
-- Start comment

a: 10 + 4 -- End of line comment
--/ Single-line block comment --\

-- Block comment inside line comment: --/ blah blah blah --\

--/
-- Comments nested in block comment
-- Another one
b: b * 10 -- Commented-out line of code
--\
b: a * a
c: a/b

-- Disabled block comment

---/
a <- a * 2
--\
a -> result
-- Final comment
]]
  lu.assertEquals(self:fullTest(input, true), 28)
end

function module:testKeywordExcludeRules()
  local errorReporter, result = module.parse(wrapWithEntrypoint'return1')
  lu.assertEquals(result, false)
  errorReporter, result = module.parse(wrapWithEntrypoint':a = 1   returna')
  lu.assertEquals(result, false)
  errorReporter, result = module.parse(wrapWithEntrypoint'result <- 1')
  lu.assertEquals(result, false)
  errorReporter, result = module.parse(wrapWithEntrypoint'result() -> none')
  lu.assertEquals(result, false)

  lu.assertEquals(self:fullTest('delta x: = 1   delta x -> result', true), 1)

  lu.assertEquals(self:fullTest('result of the variable: 1   result of the variable -> result', true), 1)
end

function module:testFullProgram()
  local input =
[[
-- a is 14
a: 10 + 4
--/
  14 * 14 - 10 = 186
--\
b: a * a - 10
-- (186 + 10)/14
c: (b + 10)/a
c -> result
]]
  lu.assertEquals(self:fullTest(input, true), 14)
end

function module:testLessonFourEdgeCases()
  local errorReporter, ast, code, result

  errorReporter, ast = module.parse(wrapWithEntrypoint('returned: 10   returned -> result'))
  errorReporter = module.typeChecker.check(ast)
  errorReporter, code = module.toStackVM.translate(ast)
  lu.assertNotEquals(code, nil)
  errorReporter, result = module.interpreter.execute(code)
  lu.assertEquals(result, 10)

  errorReporter, result = module.parse(
    [[
      :x=1
      returnx
    ]])
  lu.assertEquals(result, false)
  errorReporter, result = module.parse(
    [[
      --/
      bla bla
    ]])
  lu.assertEquals(result, false)
  errorReporter, result = module.parse(wrapWithEntrypoint'--/--\\')
  lu.assertEquals(result[1].assignment.body, {tag = 'emptyStatement'})

  errorReporter, result = module.parse(wrapWithEntrypoint'--/--/--\\')
  lu.assertEquals(result[1].assignment.body, {tag = 'emptyStatement'})

  errorReporter, result = module.parse(wrapWithEntrypoint[[
      --/
      :x=1
      --\
    ]])
  lu.assertEquals(result[1].assignment.body, {tag = 'emptyStatement'})

  lu.assertEquals(self:fullTest(
    [[
      --/--\x:1
      x -> result
    ]], true), 1)

  lu.assertEquals(self:fullTest(
    [[
      --/--\ x:10 --/--\
      x -> result
    ]], true), 10)
  lu.assertEquals(self:fullTest(
        [[
        ---/
        x:10
        --\
        x -> result
        ]], true), 10)
end

function module:testNot()
    local input = entryPointName .. ': () -> number' .. ' { if ! (1.5~=0) { 1 -> result } else { 0 -> result } }'
    lu.assertEquals(self:fullTest(input), 0)

    input = entryPointName .. ': () -> number' .. ' { if ! ! (167~=0){ 1 -> result } else { 0 -> result } }'
    lu.assertEquals(self:fullTest(input), 1)

    input = entryPointName .. ': () -> number' .. ' { if!!!(12412.435~=0) { 1 -> result } else { 0 -> result }}'
    lu.assertEquals(self:fullTest(input), 0)
end

function module:testIf()
local input =
[[a: 10 + 4
b: a * a - -10
c: a/b
if c < a {
  this is a long name: 24
  c <- 12
}
c -> result
]]
    lu.assertEquals(self:fullTest(input, true), 12)
end

function module:testIfElseElseIf()
  local ifOnlyYes =
[[a: = 20
b: 10
if b < a {
  b <- 1
}
b -> result
]]

  lu.assertEquals(self:fullTest(ifOnlyYes, true), 1)

  local ifOnlyNo =
[[a: = 20
b: = 100
if b < a {
  b <- 1
}
b -> result
]]

  lu.assertEquals(self:fullTest(ifOnlyNo, true), 100)

  local ifElseYes =
[[a: 20
b: 10
if b < a {
  b <- 1
} else {
  b <- 2
}
b -> result
]]

  lu.assertEquals(self:fullTest(ifElseYes, true), 1)

  local ifElseNo =
[[a: 20
b: 100
if b < a {
  b <- 1
} else {
  b <- 2
}
b -> result
]]

  lu.assertEquals(self:fullTest(ifElseNo, true), 2)

  local ifElseIfYes =
[[a: 20
b: 10
if b < a {
  b <- 1
} elseif b > a {
  b <- 2
}
b -> result
]]

  lu.assertEquals(self:fullTest(ifElseIfYes, true), 1)

    local ifElseIfNo =
[[a: 20
b: 100
if b < a {
  b <- 1
} elseif b > a {
  b <- 2
}
b -> result
]]

  lu.assertEquals(self:fullTest(ifElseIfNo, true), 2)

  local ifElseIfNeither =
[[a: 20
b: a
if b < a {
  b <- 1
} elseif b > a {
  b <- 2
}
b -> result
]]

  lu.assertEquals(self:fullTest(ifElseIfNeither, true), 20)
  local firstClause =
[[a: 20
b: 10
if b < a {
  b <- 1
} elseif b > a {
  b <- 2
} else {
  b <- 3
}
b -> result
]]
  lu.assertEquals(self:fullTest(firstClause, true), 1)

  local secondClause =
[[a: 20
b: 100
if b < a {
  b <- 1
} elseif b > a {
  b <- 2
} else {
  b <- 3
}
b -> result
]]
  lu.assertEquals(self:fullTest(secondClause, true), 2)
  local thirdClause =
[[a: 20
b: a
if b < a {
b <- 1
} elseif b > a {
b <- 2
} else {
b <- 3
}
b -> result
]]

  lu.assertEquals(self:fullTest(thirdClause, true), 3)

  local empty =
[[a: 20
b: a
if b < a {
} elseif b > a {
} else {
}
b -> result
]]

  lu.assertEquals(self:fullTest(empty, true), 20)
end

function module:testShortCircuit()
  local shortCircuit = [[
a: 20
b: 10
if b > a & 1/2 = 0.5 {
  b <- 100
}
b -> result
]]

  local ast, code, result, errorReporter
  errorReporter, ast = module.parse(wrapWithEntrypoint(shortCircuit))
  errorReporter = module.typeChecker.check(ast)
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
a: 20
b: 10
if b < a | 1/2 = 0.5 {
  b <- 100
}
b -> result
]]

  errorReporter, ast = module.parse(wrapWithEntrypoint(shortCircuit2))
  errorReporter = module.typeChecker.check(ast)
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
  a: 1
  b: 10
  while a < b {
    a <- a + 1
  }

  a -> result
}
]]
  lu.assertEquals(self:fullTest(input), 10)
end

function module:testArrays()
  local input =
[[entry point: () -> number {
  array: new[2][2] true
  array[1][1] <- false

  test: true
  test <- test & array[1][2]
  test <- test & array[2][1]
  test <- test & array[2][2]

  if test {
    1 -> result
  } else {
    0 -> result
  }
}
]]
  lu.assertEquals(self:fullTest(input), 1)
end

function module:testArrayNonNumeralIndexing()
  local input =
[[entry point: () -> number {
  array: new[2][2 + 2] true
  array[1][1] <- false

  subArray: new[2 + 2] true

  array[1] <- subArray

  test: true
  test <- test & array[1][2]
  test <- test & array[2][1]
  test <- test & array[2][2]

  if test {
    1 -> result
  } else {
    0 -> result
  }
}
]]

  lu.assertEquals(self:fullTest(input), 'Type checking failed!')
end

function module:testPassingAndReturningArrays()
  local input =
[[test11: (n:[2][2] boolean) -> boolean {
  n[1][1] -> result
}

testReturnArray: () -> [2][2] boolean {
  array: new[2][2] true
  array[1][1] <- true
  array -> result
}

entry point: () -> number {
  array: new[2][2] true
  --array[1][1] <- false
  testResult: = test11(testReturnArray())

  if testResult = true {
    1 -> result
  } else {
    0 -> result
  }
}
]]

  lu.assertEquals(self:fullTest(input), 1)

  input =
[[test11: (n:[2][2] boolean) -> boolean {
  n[1][1] -> result
}

testReturnArray: () -> [2][2] boolean {
  array: new[2][2] true
  array[1][1] <- false
  array -> result
}

entry point: () -> number {
  array: new[2][2] true
  --array[1][1] <- false
  testResult: test11(testReturnArray())

  if testResult = true {
    1 -> result
  } else {
    0 -> result
  }
}
]]

  lu.assertEquals(self:fullTest(input), 0)
end

function module:testFunctionCall()
  local input =
[[
another function: () -> number {
  12 -> result
}

entry point: () -> number {
  24 + another function() -> result
}
]]

  lu.assertEquals(self:fullTest(input), 36)
end

function module:testDuplicateFunctions()
  local input =
[[another function: () -> number {
  33 -> result
}

another function: () -> number {
  42 -> result
}

entry point: () -> number {
  a: 1

  a <- 23 + another function()
  a -> result
}

another function: () -> number {
  3 -> result
}
]]

  local errorReporter, ast = module.parse(input)
  lu.assertEquals(type(ast), 'table')

  errorReporter = module.typeChecker.check(ast)

  local code
  errorReporter, code = module.toStackVM.translate(ast, errorReporter)
  lu.assertEquals(errorReporter:count(), 4)

  input =
[[another function: () -> number {
  33 -> result
}

another function: () -> number {
  42 -> result
}

entry point: () -> number {
  a: 1

  a <- 23 + another function()
  a -> result
}
entry point: () -> number {
}


another function: () -> number {
  3 -> result
}
]]
  errorReporter, ast = module.parse(input)
  lu.assertEquals(type(ast), 'table')

  errorReporter = module.typeChecker.check(ast)

  errorReporter, code = module.toStackVM.translate(ast, errorReporter)
  lu.assertEquals(errorReporter:count(), 7)
end

function module:testIndirectRecursion()
  local input =
[[entry point: () -> number {
  n:global = 10
  if even() = true {
    1 -> result
  } else {
    0 -> result
  }
}
even: () -> boolean {
  if n ~= 0 {
    n <- n - 1
    odd() -> result
  } else {
    true -> result
  }
}
odd: () -> boolean {
  if n ~= 0 {
    n <- n - 1
    even() -> result
  } else {
    false -> result
  }
}
]]


  lu.assertEquals(self:fullTest(input), 1)

  input =
[[
entry point: () -> number {
  n:global = 11
  if even() = true {
    1 -> result
  } else {
    0 -> result
  }
}
even: () -> boolean {
  if n ~= 0 {
    n <- n - 1
    odd() -> result
  } else {
    true -> result
  }
}
odd: () -> boolean {
  if n ~= 0 {
    n <- n - 1
    even() -> result
  } else {
    false -> result
  }
}
]]
  lu.assertEquals(self:fullTest(input), 0)

input =
[[
entry point: () -> number {
  n:global = 10
  if odd() = true {
    1 -> result
  } else {
    0 -> result
  }
}
even: () -> boolean {
  if n ~= 0 {
    n <- n - 1
    odd() -> result
  } else {
    true -> result
  }
}
odd: () -> boolean {
  if n ~= 0 {
    n <- n - 1
    even() -> result
  } else {
    false -> result
  }
}
]]


  lu.assertEquals(self:fullTest(input), 0)

  input =
[[
entry point: () -> number {
  n:global = 11
  if odd() = true {
    1 -> result
  } else {
    0 -> result
  }
}
even: () -> boolean {
  if n ~= 0 {
    n <- n - 1
    odd() -> result
  } else {
    true -> result
  }
}
odd: () -> boolean {
  if n ~= 0 {
    n <- n - 1
    even() -> result
  } else {
    false -> result
  }
}
]]
  lu.assertEquals(self:fullTest(input), 1)
end

-- test local variables
function module:testLocalVariableCreation()
  local input =
[[entry point: () -> number {
  x:number = 1
  y:number = 2

  10 -> result
}
]]

  lu.assertEquals(self:fullTest(input), 10)
end

function module:testDefaultValueForLocalVariables()
  local input =
[[entry point: () -> number {
  x:number = 10
  y:default number

  y + x -> result
}
]]

  lu.assertEquals(self:fullTest(input), 10)
end

function module:testMixingGlobalsAndLocals()
  local input =
[[helper: () -> number {
  10 -> result
}

entry point: () -> number {
  x:number = 10
  y:default number

  z:global number = 12

  1 + helper() + z -> result
}
]]

  lu.assertEquals(self:fullTest(input), 23)
end

-- test local variable usage
function module:testLocalVariableUsage()
  local input =
[[entry point: () -> number {
  x:number = 10
  y:number = 20
  {
    x:number = 30
    y <- x + 3
  }
  y -> result
}
]]

  lu.assertEquals(self:fullTest(input), 33)
end

function module:testLocalVariableShadowingAndNameCollision()
  local input =
[[entry point: () -> number {
    x: 10
    y: 20
    {
      y: 30
      y <- x + 3
    }
    y -> result
}
]]

  lu.assertEquals(self:fullTest(input), 20)

input =
[[entry point: () -> number {
    x: 10
    y: 20
    {
      y: 30
      y <- y + 3
      y -> result
    }
}
]]

  lu.assertEquals(self:fullTest(input), 33)

input =
[[entry point: () -> number {
    x: 10
    x: 11
    y: 20
    {
      y: 30
      y: 10
      y <- y + 3
      y -> result
    }
}
]]
  local errorReporter, ast = module.parse(input)
  lu.assertNotEquals(ast, nil)
  errorReporter = module.typeChecker.check(ast)
  local code
  errorReporter, code = module.toStackVM.translate(ast)
  lu.assertEquals(errorReporter:count(), 2)
end

function module:testWrongFunctionArgumentTypes()
  local input =
[[test: (n:number) -> number {
  n -> result
}
entry point: -> number {
  test(true) -> none
}
]]

  lu.assertEquals(self:fullTest(input), 'Type checking failed!')
end

-- test function parameter count mismatch (zero when should be something, number when should be another number, something when should be zero.)
function module:testParameterArgumentCountMismatch()
  -- Matching
  local input =
[[test: (n:number) -> number {
  n -> result
}

entry point: () -> number {
  test(2) -> result
}
]]

  lu.assertEquals(self:fullTest(input), 2)

  -- Sent nothing, should be sent one
  input =
[[test: (n:number) -> number {
  n -> result
}

entry point: () -> number {
  test() -> result
}
]]

  lu.assertEquals(self:fullTest(input), 'Translation failed!')

  -- Sent one, should have sent two
  input =
[[test: (n:number n2:number) -> number {
  n -> result
}

entry point: () -> number {
  test(2) -> result
}
]]

  lu.assertEquals(self:fullTest(input), 'Translation failed!')

  -- Sent one, should not have sent any
  input =
[[test: () -> number {
}

entry point: () -> number {
  test(2) -> result
}
]]

  lu.assertEquals(self:fullTest(input), 'Translation failed!')
end

function module:testDuplicateFunctionParameters()
  local input =
[[manyCollisions: (n:number n:number g:number g:number g:number b:number) -> number
   {
}

entry point: () -> number {
  manyCollisions(1, 1, 2, 2, 2, 3) -> result
}
]]

  lu.assertEquals(self:fullTest(input), 'Translation failed!')
end

function module:testFactorial()
  local input =
[[factorial: (n:number)-> number {
  if n <= 0 {
    1 -> result
  }

  n * factorial(n - 1) -> result
}

entry point: () -> number {
  factorial(10) -> result
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
  a + b -> result
}
entry point: () -> number {
  sum(65,24) -> result
}
]]
  lu.assertEquals(self:fullTest(input), 89)

  input =
[[sum: (a:number b:number) -> number {
  a + b -> result
}
entry point: () -> number {
  a:number = 10
  b:number = 24

  sum(a * 12,b) -> result
}
]]

  lu.assertEquals(self:fullTest(input), 144)
end

function module:testTernaryOperator()
  local input =
[[entry point: () -> number {

    x: 12
    y: 10

    testResult: x > y ? true : false

    if testResult = true {
        1 -> result
    } else {
        0 -> result
    }
}
]]
  lu.assertEquals(self:fullTest(input), 1)

  input =
  [[entry point: () -> number {

      x: 10
      y: 12

      testResult: x > y ? true : false

      if testResult = true {
          1 -> result
      } else {
          0 -> result
      }
  }
  ]]

  lu.assertEquals(self:fullTest(input), 0)

  -- Not a boolean
  input =
  [[entry point: () -> number {

      x: 10
      y: 12

      testResult: x + y ? true : false

      if testResult = true {
          1 -> result
      } else {
          0 -> result
      }
  }
  ]]

  lu.assertEquals(self:fullTest(input), 'Type checking failed!')

  -- Mismatched types in branches
  input =
  [[entry point: () -> number {

      x: 10
      y: 12

      testResult: x < y ? true : 0

      if testResult = true {
          1 -> result
      } else {
          0 -> result
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
  }

  factorial: (n:number) -> number {
      if n = 0 {
          1 -> result
      } else {
          n * factorial(n - 1) -> result
      }
  }

  sum: (a:number b:number) -> number = {
      a + b -> result
  }

  -- Commas can be included:
  div: (a:number, b:number) -> number {
      a / b -> result
  }

  -- This could also be written as " entry point: -> number ."
  entry point: () -> number {
      global container() -> none

      -- Fully specified variable
      a:local number = 2
      -- Equals is optional...
      b:= 2
      -- Other than the name, the same as the two previous.
      c: 2

      factorial( div( sum( a, b ) * c, 2) ) -> result
  }
  ]]

  lu.assertEquals(self:fullTest(input), 24.0)
end

function module:testDefaultArguments()
  -- Default with one parameter
  --  Used:
  local input =
  [[default arguments: (n:number = 12 * 17) -> number {
    n -> result
  }

  entry point: -> number {
    default arguments() -> result
  }
  ]]

  lu.assertEquals(self:fullTest(input), 12 * 17)
  --  Not used:
  input =
  [[default arguments: (n:number = 12 * 17) -> number {
    n -> result
  }

  entry point: -> number {
    default arguments(12) -> result
  }
  ]]
  lu.assertEquals(self:fullTest(input), 12)

  -- Default with multiple parameters:
  --  Used:
  input =
  [[default arguments: (b:boolean n:number = 12 * 17) -> number {
    n -> result
  }

  entry point: -> number {
    default arguments(true) -> result
  }
  ]]
  lu.assertEquals(self:fullTest(input), 12 * 17)

  --  Not used:
  input =
  [[default arguments: (b:boolean n:number = 12 * 17) -> number {
    n -> result
  }

  entry point: -> number {
    default arguments(true, 12) -> result
  }
  ]]
  lu.assertEquals(self:fullTest(input), 12)
end

function module:testMismatchedFunctionAssignments()
  -- Mismatched parameter types
  local input =
  [[test: (b:boolean n:number) -> number {
  }

  test2: -> number {
  }

  entry point: -> number {
    test <- test2
  }
  ]]
  lu.assertEquals(self:fullTest(input), 'Type checking failed!')

  -- Mismatched result types
  input =
  [[test: (b:boolean n:number) -> number {
  }

  test2: -> boolean {
  }

  entry point: -> number {
    test <- test2
  }
  ]]
  lu.assertEquals(self:fullTest(input), 'Type checking failed!')


  -- Mismatched parameter types with multiple parameters
  input =
  [[
testMismatches:           (b:boolean, n:number, func: (n:number) ->) -> number {
}

testMismatchedParameter:  (b:boolean, n:boolean, func: (n:number) ->) -> number {
}

testMismatchedResultType: (b:boolean, n:number, func: (n:number) ->) -> boolean {
}

entry point: -> number {
  testMismatches <- testMismatchedParameter
}
  ]]
  lu.assertEquals(self:fullTest(input), 'Type checking failed!')

  input =
  [[
testMismatches:           (b:boolean, n:number, func: (n:number) ->) -> number {
}

testMismatchedParameter:  (b:boolean, n:boolean, func: (n:number) ->) -> number {
}

testMismatchedResultType: (b:boolean, n:number, func: (n:number) ->) -> boolean {
}

entry point: -> number {
  testMismatches <- testMismatchedResultType
}
  ]]
  lu.assertEquals(self:fullTest(input), 'Type checking failed!')
end


-- Test function within another function
function module:testFunctionWithinFunction()
  local input =
  [[entry point: -> number {
    a local function: -> number {
      33 -> result
    }

    a local function() -> result
  }
  ]]

  lu.assertEquals(self:fullTest(input), 33)
end

-- Test function assignment
function module:testFunctionAssignment()
  local input =
  [[test: -> number {
    33 -> result
  }

  entry point: -> number {
    test2: -> number = test

    test2() -> result
  }
  ]]

  lu.assertEquals(self:fullTest(input), 33)

  -- Test function assignment of existing function
  input =
  [[test return anything: -> number {}

test return 10: -> number {
  10 -> result
}

entry point: -> number {
  test return anything <- test return 10

  test return anything() -> result
}]]

  lu.assertEquals(self:fullTest(input), 10)
end

function module:testArrayFunctionCallAndAssignment()
  local input =
[[to number: -> number {
  33 -> result
}

to 12: -> number {
  12 -> result
}

entry point: -> number {

    array: new[10][2] to number

    i: 1
    while i <= 10 {
      array[i][1] <- to 12

      i <- i + 1
    }

    sum: 0

    i <- 1
    while i <= 10 {
      j: 1
      while j <= 2 {
        sum <- sum + array[i][j]()
        j <- j + 1
      }
      i <- i + 1
    }

  sum -> result
}]]

  lu.assertEquals(self:fullTest(input), 450)
end

function module:testStrings()
  local input =
[[entry point: -> number {
    a string: ''a string 'this is single quoted' and the end''
    a string <- ''a string "this is double quoted" and the end''
a string <- ''this is a multiline
string using the same basic syntax, and you can insert single quotes as ' or double quotes as "''

a unicode string: ''This is a string in UTF-8: 'いづれの御時にか、女御、更衣あまたさぶらひたまひけるなかに、いとやむごとなき際にはあらぬが、すぐれて時めきたまふありけり。'''

a string with the at character as an escape: '@
        this is a string that will continuing until an @s character appears by itself.@

a string <- a unicode string
}]]

  lu.assertEquals(self:fullTest(input), 0)
  
  input =
[[entry point: -> number {
a string: ''a string 'this is single quoted' and the end''
a string <- ''a string "this is double quoted" and the end''
a string <- ''this is a multiline
string using the same basic syntax, and you can insert single quotes as ' or double quotes as "''
a string with the at character as the end delimiter: '@
        this is a string that will continue until an @s character appears by itself.@

multiple ats: '3@This string continues until at least three @ characters appear.@@@2@@@

a unicode string: ''This is a string in UTF-8: 'いづれの御時にか、女御、更衣あまたさぶらひたまひけるなかに、いとやむごとなき際にはあらぬが、すぐれて時めきたまふありけり。's''

a more traditional string: ""1This string is enclosed in double quotes."1"

2nd more traditional string: ""sThis string is enclosed in double quotes."s"

a string with leading spaces: ''
        this string has leading spaces
        they are all stripped''
}]]
  
  lu.assertEquals(self:fullTest(input), 0)

  input =
[[entry point: -> number {
  s:''
     This string's terminated in two single quotes.
     You can include "double quotes" and 'single quotes'
     in this string without needing to escape them.''

  s<-'@This is a string ending at the first @s symbol (other than the escaped one) '"\/!#$%^&*().@

  s<-'3@You don't even need to escape single @s in this string. Only @@@s need to be escaped.@@@

  s<-'2'This is a string ending in two single quotes.''
  s<-'"This is a string that is terminated by a "s."'
  s<-'1"This is a string that is terminated by a "s."
  s<-'1@This is a string that is terminated by an @s.@'
  s<-'3@This string ends in three @s @@@@@@'
  s<-'''This string is surrounded by single quotes.'''
  s<-'3@This string ends in three @s @@@s@@@'
}]]
  
  lu.assertEquals(self:fullTest(input), 0)

end

function module:testComplexFirstClassFunctions()
  local input =
[[
test return 10: -> number {
  10 -> result
}
test return 20: -> number {
  20 -> result
}

testReturnLocalFunction: -> -> number {
  a local function: -> number {
    a: 33
    {
      b: 22
      a <- a + b
    }
    a -> result
  }

  a local function -> result
}

entry point: -> number {
  test return anything: 10 > 20 ? test return 10 : test return 20

  a local function: -> number {
    33 -> result
  }

  lf: testReturnLocalFunction()

  lf() -> result
}
]]

  lu.assertEquals(self:fullTest(input), 55)

  input =
[[test return 10: -> number {
  10 -> result
}
test return 20: -> number {
  20 -> result
}

testReturnLocalFunction: -> -> number {
  internal local function: -> number {
    a: 33
    {
      b: 22
      a <- a + b
    }
    a -> result
  }

  internal local function -> result
}


entry point: -> number {
  test return anything: 10 > 20 ? test return 10 : test return 20

  a local function: -> number {
    a: 33
    {
      b: 22
      a <- a + b
    }
    a -> result
  }

  a local function() -> none

  lf: testReturnLocalFunction()

  lf() -> result
}
]]
  lu.assertEquals(self:fullTest(input), 55)
  
  input =
[[entry point: -> number {
  lf: (n:number) -> number { n -> result }

  12 -> result
}]]

  lu.assertEquals(self:fullTest(input), 12)

  -- Function returning nothing
  input =
[[test:(a:number, b:number) -> {
  local variable: 10
  exit
}

entry point: -> number {
  test(7, 12) -> none
  12 -> result
}]]
  lu.assertEquals(self:fullTest(input), 12)

  -- Function returning nothing,
  -- and local function defined but not called.
  input =
[[test:(a:number, b:number) -> {
  local variable: 10
  exit
}

entry point: -> number {
  lf: (n:number) -> number { n -> result }

  test(7, 12) -> none
  12 -> result
}]]

  lu.assertEquals(self:fullTest(input), 12)

end

function module:testOffsetIndexing()
  local input =
[[entry point: -> number {
    a: new [2][2] 3
    a+[0][0] <- 0
    a+[0][1] <- 1
    a+[1][0] <- 10
    a+[1][1] <- 11

    a+[0][0] + a+[0][1] + a+[1][0] + a+[1][1] -> result
}
]]

  lu.assertEquals(self:fullTest(input), 22)

  -- Test with an array with different sizes in each dimension:
  input =
[[entry point: -> number {
    a: new [2][3] 3
    a+[0][0] <- 0
    a+[0][1] <- 1
    a+[0][2] <- 2
    a+[1][0] <- 10
    a+[1][1] <- 11
    a+[1][2] <- 12

    a+[0][0] + a+[0][1] + a+[0][2] + a+[1][0] + a+[1][1] + a+[1][2] -> result
}
]]

  lu.assertEquals(self:fullTest(input), 36)
end

-- Aspirational. The issue is that expressions can't contain blocks.
-- Basically, this is a test of lambdas.
--function module:testCreateFunctionWithTernaryExpressionBodies()
--  local input =
--[[entry point: -> number {
--  returning parameter: (n:number) -> number = true ? { a: n   b: n   return b   } : { b: n   return -b   }
--
--  c:10
--
--  return returning parameter(12)
--}
--]]
--
--  lu.assertEquals(self:fullTest(input), 12)
--end
--
return module