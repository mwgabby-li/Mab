-- Mab Frontend Test Suite (AST generation)
local lu = require 'External.luaunit'
-- Most recent supported version
local astVersion = 1
local module = {}

function module:init(parse, typeChecker, toStackVM, interpreter)
    module.parse = parse
    module.typeChecker = typeChecker
    module.toStackVM = toStackVM
    module.interpreter = interpreter
    return module
end

function module:testAssignmentAndParentheses()
  local input = 'i = (1 + 2) * 3'
  local ast = module.parse(input)
  local expected = {
    version = astVersion,
    tag="assignment",
    writeTarget={tag="variable", position=1, value="i"},
    position=5,
    assignment={
        tag="binaryOp",
        firstChild={
            tag="binaryOp",
            firstChild={tag="number", position=6, value=1},
            position=8,
            op="+",
            secondChild={tag="number", position=10, value=2},
        },
        position=13,
        op="*",
        secondChild={tag="number", position=15, value=3},
    },
  }
  lu.assertEquals(ast, expected)
end

function module:testReturn()
  local input = 'return 1 + 2'
  local ast = module.parse(input)
  local expected = {
    version = astVersion,
    position=8,
    sentence={
        firstChild={tag="number", position=8, value=1},
        op="+",
        position=10,
        secondChild={tag="number", position=12, value=2},
        tag="binaryOp"
    },
    tag="return"
  }
  lu.assertEquals(ast, expected)
end

function module:testAssignmentAndReturn()
    local input = 'i = 4 * 3; @ i * 64; return i;'
    local ast = module.parse(input)
    local expected = {
      version = astVersion,
      firstChild={
          assignment={
              firstChild={tag="number", position=5, value=4},
              op="*",
              position=7,
              secondChild={tag="number", position=9, value=3},
              tag="binaryOp"
          },
          position=5,
          tag="assignment",
          writeTarget={tag="variable", position=1, value="i"}
      },
      secondChild={
          firstChild={
              position=14,
              tag="print",
              toPrint={
                  firstChild={tag="variable", position=14, value="i"},
                  op="*",
                  position=16,
                  secondChild={tag="number", position=18, value=64},
                  tag="binaryOp"
              }
          },
          secondChild={position=29, sentence={tag="variable", position=29, value="i"}, tag="return"},
          tag="statementSequence"
      },
      tag="statementSequence"
    }
    lu.assertEquals(ast, expected)
end

function module.testEmptyStatements()
    local input = ';;;;'
    local ast = module.parse(input)
    local expected = {
        version = astVersion,
        tag = 'emptyStatement'
    }
    lu.assertEquals(ast, expected)
end

function module.testEmptyInput()
    local input = ''
    local ast = module.parse(input)
    local expected = {
        version = astVersion,
        tag = 'emptyStatement'
    }
    lu.assertEquals(ast, expected)
end

function module.testStackedUnaryOperators()
    local input = 'i = - - - - 4 * 3'
    local ast = module.parse(input)
    local expected = {
    version = astVersion,
    assignment={
        firstChild={
            child={
                child={
                    child={child={tag="number", position=13, value=4}, op="-", position=13, tag="unaryOp"},
                    op="-",
                    position=11,
                    tag="unaryOp"
                },
                op="-",
                position=9,
                tag="unaryOp"
            },
            op="-",
            position=7,
            tag="unaryOp"
        },
        op="*",
        position=15,
        secondChild={tag="number", position=17, value=3},
        tag="binaryOp"
    },
    position=5,
    tag="assignment",
    writeTarget={tag="variable", position=1, value="i"}
    }
    lu.assertEquals(ast, expected)
end

function module.testUnaryOperators()
    local input = 'i = -4 * 3'
    local ast = module.parse(input)
    local expected = {
      version = astVersion,
      assignment={
          firstChild={child={tag="number", position=6, value=4}, op="-", position=6, tag="unaryOp"},
          op="*",
          position=8,
          secondChild={tag="number", position=10, value=3},
          tag="binaryOp"
      },
      position=5,
      tag="assignment",
      writeTarget={tag="variable", position=1, value="i"}
    }
    lu.assertEquals(ast, expected)
end

function module.testEmptyStatementsLeadingTrailing()
    local input = ';;;;i = 4 * 3;;;;'
    local ast = module.parse(input)
    local expected = {
      version = astVersion,
      assignment={
          firstChild={tag="number", position=9, value=4},
          op="*",
          position=11,
          secondChild={tag="number", position=13, value=3},
          tag="binaryOp"
      },
      position=9,
      tag="assignment",
      writeTarget={tag="variable", position=5, value="i"}
    }
    lu.assertEquals(ast, expected)
end

function module.testEmptyStatementsInterspersed()
    local input = ';;;;i = 4 * 3;;;;@ i * 64;;;;return i;;;;'
    local ast = module.parse(input)
    local expected = {
      version = astVersion,
      firstChild={
          assignment={
              firstChild={tag="number", position=9, value=4},
              op="*",
              position=11,
              secondChild={tag="number", position=13, value=3},
              tag="binaryOp"
          },
          position=9,
          tag="assignment",
          writeTarget={tag="variable", position=5, value="i"}
      },
      secondChild={
          firstChild={
              position=20,
              tag="print",
              toPrint={
                  firstChild={tag="variable", position=20, value="i"},
                  op="*",
                  position=22,
                  secondChild={tag="number", position=24, value=64},
                  tag="binaryOp"
              }
          },
          secondChild={position=37, sentence={tag="variable", position=37, value="i"}, tag="return"},
          tag="statementSequence"
      },
      tag="statementSequence"
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

function module.testExponentPrecedence()
    local input = 'i = 2 ^ 3 ^ 4'
    local ast = module.parse(input)
    local expected = {
      version = astVersion,
      assignment={
          firstChild={tag="number", position=5, value=2},
          op="^",
          position=7,
          secondChild={
              firstChild={tag="number", position=9, value=3},
              op="^",
              position=11,
              secondChild={tag="number", position=13, value=4},
              tag="binaryOp"
          },
          tag="binaryOp"
      },
      position=5,
      tag="assignment",
      writeTarget={tag="variable", position=1, value="i"}
    }
    lu.assertEquals(ast, expected)
end

function module.testBlockAndLineComments()
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
b = a * a - 10;
c = a/b;

# Disabled block comment

##{
@c;
#}
return c;
# Final comment
]]
    local ast = module.parse(input)
    local expected = {
      version = astVersion,
      firstChild={
          assignment={
              firstChild={tag="number", position=22, value=10},
              op="+",
              position=25,
              secondChild={tag="number", position=27, value=4},
              tag="binaryOp"
          },
          position=22,
          tag="assignment",
          writeTarget={tag="variable", position=18, value="a"}
      },
      secondChild={
          firstChild={
              assignment={
                  firstChild={
                      firstChild={tag="variable", position=244, value="a"},
                      op="*",
                      position=246,
                      secondChild={tag="variable", position=248, value="a"},
                      tag="binaryOp"
                  },
                  op="-",
                  position=250,
                  secondChild={tag="number", position=252, value=10},
                  tag="binaryOp"
              },
              position=244,
              tag="assignment",
              writeTarget={tag="variable",  position=240, value="b"}
          },
          secondChild={
              firstChild={
                  assignment={
                      firstChild={tag="variable", position=260, value="a"},
                      op="/",
                      position=261,
                      secondChild={tag="variable", position=262, value="b"},
                      tag="binaryOp"
                  },
                  position=260,
                  tag="assignment",
                  writeTarget={tag="variable", position=256, value="c"}
              },
              secondChild={
                  firstChild={position=297, tag="print", toPrint={tag="variable", position=297, value="c"}},
                  secondChild={position=310, sentence={tag="variable", position=310, value="c"}, tag="return"},
                  tag="statementSequence"
              },
              tag="statementSequence"
          },
          tag="statementSequence"
      },
      tag="statementSequence"
    }
    lu.assertEquals(ast, expected)
end

function module.testKeywordExcludeRules()
  lu.assertEquals(module.parse('return1'), nil)
  lu.assertEquals(module.parse('a = 1; returna'), nil)
  lu.assertEquals(module.parse('return = 1'), nil)
  lu.assertEquals(module.parse('return return'), nil)
  lu.assertEquals(module.parse('delta x = 1; return delta x'),
    {
      version = astVersion,
      firstChild={
        assignment={tag="number", position=11, value=1},
        position=11,
        tag="assignment",
        writeTarget={tag="variable", position=1, value="delta x"}
      },
      secondChild={
        position=21,
          sentence={tag="variable", position=21, value="delta x"},
        tag="return"},
      tag="statementSequence"
    }
  )
  lu.assertEquals(module.parse('return of the variable = 1; return return of the variable'),
    {
      version = astVersion,
      firstChild={
          assignment={tag="number", position=26, value=1},
          position=26,
          tag="assignment",
          writeTarget={tag="variable", position=1, value="return of the variable"}
      },
      secondChild={
          position=36,
          sentence={tag="variable", position=36, value="return of the variable"},
          tag="return"
      },
      tag="statementSequence"
    }
  )
end

function module.testFullProgram()
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
  local ast = module.parse(input)
  local code = module.toStackVM.translate(ast)
  local result = module.interpreter.run(code)
  lu.assertEquals(result, 14)
end

function module.testLessonFourEdgeCases()
  lu.assertEquals(module.parse 'returned = 10',
    {
      version = astVersion,
      assignment={tag="number", position=12, value=10},
      position=12,
      tag="assignment",
      writeTarget={tag="variable", position=1, value="returned"}
    }
  )
  lu.assertEquals(module.parse 'x=10y=20', nil)
  
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
  
  lu.assertEquals(module.parse '#{##}', {version = astVersion, tag = 'emptyStatement'})
  
  lu.assertEquals(module.parse '#{#{#}', {version = astVersion, tag = 'emptyStatement'})
  
  lu.assertEquals(module.parse(
    [[
      #{
      x=1
      #}
    ]]), {version = astVersion, tag = 'emptyStatement'})
    
  lu.assertEquals(module.parse(
    [[
      #{#}x=1;
      return x
    ]]),
    {
      version = astVersion,
      firstChild={
          assignment={tag="number", position=13, value=1},
          position=13,
          tag="assignment",
          writeTarget={tag="variable", position=11, value="x"}
      },
      secondChild={position=29, sentence={tag="variable", position=29, value="x"}, tag="return"},
      tag="statementSequence"
    })
  
  lu.assertEquals(module.parse(
    [[
      #{#} x=10; #{#}
      return x
    ]]),
    {
      version = astVersion,
      firstChild={
          assignment={tag="number", position=14, value=10},
          position=14,
          tag="assignment",
          writeTarget={tag="variable", position=12, value="x"}
      },
      secondChild={position=36, sentence={tag="variable", position=36, value="x"}, tag="return"},
      tag="statementSequence"
    })
    lu.assertEquals(module.parse(
        [[
        ##{
        x=10
        #}
        ]]),{
        version = astVersion,
        assignment={tag="number", position=23, value=10},
        position=23,
        tag="assignment",
        writeTarget={tag="variable", position=21, value="x"}
    })
end

function module.testNot()
    local ast = module.parse('return ! 1.5')
    lu.assertEquals(ast, {
      version = astVersion,
      position=8,
      sentence={child={tag="number", position=10, value=1.5}, op="!", position=10, tag="unaryOp"},
      tag="return"
    })
    local code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code),0)
  
    local ast = module.parse('return ! ! 167')
    lu.assertEquals(ast, {
      version = astVersion,
      position=8,
      sentence={
          child={child={tag="number", position=12, value=167}, op="!", position=12, tag="unaryOp"},
          op="!",
          position=10,
          tag="unaryOp"
      },
      tag="return"
    })
    local code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code),1)
    
    local ast = module.parse('return!!!12412.435')
    lu.assertEquals(ast, {
      version = astVersion,
      position=7,
      sentence={
          child={
              child={child={tag="number", position=10, value=12412.435}, op="!", position=10, tag="unaryOp"},
              op="!",
              position=9,
              tag="unaryOp"
          },
          op="!",
          position=8,
          tag="unaryOp"
      },
      tag="return"
    })
    local code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code),0)
end

function module.testIf()
local code = [[
a = 10 + 4;
b = a * a - -10;
c = a/b;
if c < a {
  this is a long name = 24;
  c = 12;
};
return c;
]]
  local ast = module.parse(code)
  lu.assertEquals(ast,
    {
      version = astVersion,
      firstChild={
          assignment={
              firstChild={tag="number", position=5, value=10},
              op="+",
              position=8,
              secondChild={tag="number", position=10, value=4},
              tag="binaryOp"
          },
          position=5,
          tag="assignment",
          writeTarget={tag="variable", position=1, value="a"}
      },
      secondChild={
          firstChild={
              assignment={
                  firstChild={
                      firstChild={tag="variable", position=17, value="a"},
                      op="*",
                      position=19,
                      secondChild={tag="variable", position=21, value="a"},
                      tag="binaryOp"
                  },
                  op="-",
                  position=23,
                  secondChild={child={tag="number", position=26, value=10}, op="-", position=26, tag="unaryOp"},
                  tag="binaryOp"
              },
              position=17,
              tag="assignment",
              writeTarget={tag="variable", position=13, value="b"}
          },
          secondChild={
              firstChild={
                  assignment={
                      firstChild={tag="variable", position=34, value="a"},
                      op="/",
                      position=35,
                      secondChild={tag="variable", position=36, value="b"},
                      tag="binaryOp"
                  },
                  position=34,
                  tag="assignment",
                  writeTarget={tag="variable", position=30, value="c"}
              },
              secondChild={
                  firstChild={
                      block={
                          firstChild={
                              assignment={tag="number", position=74, value=24},
                              position=74,
                              tag="assignment",
                              writeTarget={tag="variable", position=52, value="this is a long name"}
                          },
                          secondChild={
                              assignment={tag="number", position=84, value=12},
                              position=84,
                              tag="assignment",
                              writeTarget={tag="variable", position=80, value="c"}
                          },
                          tag="statementSequence"
                      },
                      expression={
                          firstChild={tag="variable", position=42, value="c"},
                          op="<",
                          position=44,
                          secondChild={tag="variable", position=46, value="a"},
                          tag="binaryOp"
                      },
                      position=42,
                      tag="if"
                  },
                  secondChild={position=98, sentence={tag="variable", position=98, value="c"}, tag="return"},
                  tag="statementSequence"
              },
              tag="statementSequence"
          },
          tag="statementSequence"
      },
      tag="statementSequence"
    })
    local code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code),12)
end

function module.testIfElseElseIf()
  local ifOnlyYes = [[
a = 20;
b = 10;
if b < a {
  b = 1
};
return b;
]]

  local ast = module.parse(ifOnlyYes)
  local code = module.toStackVM.translate(ast)
  lu.assertEquals(module.interpreter.run(code), 1)

    local ifOnlyNo = [[
  a = 20;
  b = 100;
  if b < a {
    b = 1
  };
  return b;
  ]]

  ast = module.parse(ifOnlyNo)
  code = module.toStackVM.translate(ast)
  lu.assertEquals(module.interpreter.run(code), 100)

  local ifElseYes = [[
a = 20;
b = 10;
if b < a {
  b = 1
} else {
  b = 2
};
return b;
]]

  ast = module.parse(ifElseYes)
  code = module.toStackVM.translate(ast)
  lu.assertEquals(module.interpreter.run(code), 1)

    local ifElseNo = [[
  a = 20;
  b = 100;
  if b < a {
    b = 1
  } else {
    b = 2
  };
  return b;
  ]]

  ast = module.parse(ifElseNo)
  code = module.toStackVM.translate(ast)
  lu.assertEquals(module.interpreter.run(code), 2)

  local ifElseIfYes = [[
a = 20;
b = 10;
if b < a {
  b = 1
} elseif b > a {
  b = 2
};
return b;
]]

  ast = module.parse(ifElseIfYes)
  code = module.toStackVM.translate(ast)
  lu.assertEquals(module.interpreter.run(code), 1)

    local ifElseIfNo = [[
  a = 20;
  b = 100;
  if b < a {
    b = 1
  } elseif b > a {
    b = 2
  };
  return b;
  ]]

  ast = module.parse(ifElseIfNo)
  code = module.toStackVM.translate(ast)
  lu.assertEquals(module.interpreter.run(code), 2)

  local ifElseIfNeither = [[
a = 20;
b = a;
if b < a {
  b = 1
} elseif b > a {
  b = 2
};
return b;
]]

  ast = module.parse(ifElseIfNeither)
  code = module.toStackVM.translate(ast)
  lu.assertEquals(module.interpreter.run(code), 20)
  local firstClause = [[
a = 20;
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
  ast = module.parse(firstClause);
  code = module.toStackVM.translate(ast)
  lu.assertEquals(module.interpreter.run(code), 1)

  local secondClause = [[
a = 20;
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
  ast = module.parse(secondClause);
  code = module.toStackVM.translate(ast)
  lu.assertEquals(module.interpreter.run(code), 2)
  local thirdClause = [[
a = 20;
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

  ast = module.parse(thirdClause);
  code = module.toStackVM.translate(ast)
  lu.assertEquals(module.interpreter.run(code), 3)

  local empty = [[
a = 20;
b = a;
if b < a {
} elseif b > a {
} else {
};
return b;
  ]]

  ast = module.parse(empty);
  code = module.toStackVM.translate(ast)
  lu.assertEquals(module.interpreter.run(code), 20)
end

return module