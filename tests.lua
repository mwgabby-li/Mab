-- Mab Frontend Test Suite (AST generation)
local lu = require 'External.luaunit'
local module = {}

function module:init(parse, toStackVM, interpreter)
    module.parse = parse
    module.toStackVM = toStackVM
    module.interpreter = interpreter
    return module
end

function module:testAssignmentAndParentheses()
  local input = 'i = (1 + 2) * 3'
  local ast = module.parse(input)
  local expected = {
    tag = 'assignment',
    identifier = 'i',
    assignment = {
      tag = 'binaryOp',
      firstChild = {
        tag = 'binaryOp',
        firstChild = {
          tag = 'number',
          value = 1
        },
        op = '+',
        secondChild = {
          tag = 'number',
          value = 2
        }
      },
      op = '*',
      secondChild = {
        tag = 'number',
        value = 3
      }
    }
  }
  lu.assertEquals(ast, expected)
end

function module:testReturn()
  local input = 'return 1 + 2'
  local ast = module.parse(input)
  local expected = {
    tag = 'return',
    sentence = {
      tag = 'binaryOp',
      firstChild = {
        tag = 'number',
        value = 1
      },
      op = '+',
      secondChild = {
        tag = 'number',
        value = 2
      }
    }
  }
  lu.assertEquals(ast, expected)
end

function module:testAssignmentAndReturn()
    local input = 'i = 4 * 3; @ i * 64; return i;'
    local ast = module.parse(input)
    local expected = {
            tag = 'statementSequence',
            firstChild = {
            tag = 'assignment',
            identifier = 'i',
            assignment = {
                tag = 'binaryOp',
                firstChild = {
                tag = 'number',
                value = 4
                },
                op = '*',
                secondChild = {
                tag = 'number',
                value = 3
                }
            }
        },
        secondChild = {
            tag = 'statementSequence',
            firstChild = {
                    tag = 'print',
                    toPrint = {
                    tag = 'binaryOp',
                    firstChild = {
                        tag = 'variable',
                        value = 'i'
                    },
                    op = '*',
                    secondChild = {
                        tag = 'number',
                        value = 64
                    }
                }
            },
            secondChild = {
                tag = 'return',
                sentence = {
                tag = 'variable',
                value = 'i'
                }
            }
        }
    }
    lu.assertEquals(ast, expected)
end

function module.testEmptyStatements()
    local input = ';;;;'
    local ast = module.parse(input)
    local expected = {
        tag = 'emptyStatement'
    }
    lu.assertEquals(ast, expected)
end

function module.testEmptyInput()
    local input = ''
    local ast = module.parse(input)
    local expected = {
        tag = 'emptyStatement'
    }
    lu.assertEquals(ast, expected)
end

function module.testEmptyStatementsLeadingTrailing()
    local input = ';;;;i = 4 * 3;;;;'
    local ast = module.parse(input)
    local expected = {
                tag = 'assignment',
                identifier = 'i',
                assignment = {
                    tag = 'binaryOp',
                    firstChild = {
                        tag = 'number',
                        value = 4
                    },
                    op = '*',
                    secondChild = {
                        tag = 'number',
                        value = 3
                    }
                }
        }
    lu.assertEquals(ast, expected)
end

function module.testEmptyStatementsInterspersed()
    local input = ';;;;i = 4 * 3;;;;@ i * 64;;;;return i;;;;'
    local ast = module.parse(input)
    local expected = {
            tag = 'statementSequence',
            firstChild = {
                tag = 'assignment',
                identifier = 'i',
                assignment = {
                    tag = 'binaryOp',
                    firstChild = {
                        tag = 'number',
                        value = 4
                    },
                    op = '*',
                    secondChild = {
                        tag = 'number',
                        value = 3
                    }
                }
            },
            secondChild = {
                tag = 'statementSequence',
                firstChild = {
                    tag = 'print',
                    toPrint = {
                        tag = 'binaryOp',
                        firstChild = {
                            tag = 'variable',
                            value = 'i'
                        },
                        op = '*',
                        secondChild = {
                            tag = 'number',
                            value = 64
                        }
                    }
                },
                secondChild = {
                    tag = 'return',
                    sentence = {
                        tag = 'variable',
                        value = 'i'
                    }
                }
            }
        }
    lu.assertEquals(ast, expected)
end

function module.testComplexSequenceResult()
    local input = 'x value = 12 / 2;'..
                  'y value = 12 * 12 / 2;'..
                  'z value = x value * y value % 12;'..
                  'z value = y value ^ x value + z value;'..
                  'return z value;'

    local ast = module.parse(input)
    local code = module.toStackVM.translate(ast)
    local result = module.interpreter.run(code)
    lu.assertEquals(result, 139314069504)
end

function module.testAllOperators()
    local input = 'i = 1 + 2 - 3 * 4 / 5 % 6 ^ 7'
    local ast = module.parse(input)
end

return module