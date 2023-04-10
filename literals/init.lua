local module = { op = {}, delim = {}, sep = {}, kw = {}, comment = {}  }

-- Language literals, they can be customized here.
--  Operators
module.op.assign = '='
module.op.add = '+'
module.op.subtract = '-'
module.op.multiply = '*'
module.op.divide = '/'
module.op.modulus = '%'
module.op.exponent = '^'
module.op.less = '<'
module.op.greater = '>'
module.op.lessOrEqual = '<='
module.op.greaterOrEqual = '>='
module.op.equal = '=='
module.op.notEqual = '~='
module.op.print = '@'

--  Comments
module.comment.comment = '#'
module.comment.openBlockComment = '#{'
module.comment.closeBlockComment = '}#'

--  Delimiters
module.delim.openFactor = '('
module.delim.closeFactor = ')'
module.delim.openBlock = '{'
module.delim.closeBlock = '}'

--  Separators
module.sep.endOfStatement = ';'

--  Keywords
module.kw.return_ = 'return'

module.op.toName = {
  [add] = 'add',
  [subtract] = 'subtract',
  [multiply] = 'multiply',
  [divide] = 'divide',
  [modulus] = 'modulus',
  [exponent] = 'exponent',
  [less] = 'less',
  [greater] = 'greater',
  [lessOrEqual] = 'lessOrEqual',
  [greaterOrEqual] = 'greaterOrEqual',
  [equal] = 'equal',
  [notEqual] = 'notEqual',
}

module.op.unaryToName = {
    [subtract] = 'negate',
}

return module
