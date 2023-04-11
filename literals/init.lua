local module = { op = {}, delim = {}, sep = {}, kw = {}, comments = {}  }

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
module.op.positive = '+'
module.op.negate = '-'

--  Comments
module.comments.startLine = '#'
module.comments.openBlock = '#{'
module.comments.closeBlock = '#}'

--  Delimiters
module.delim.openFactor = '('
module.delim.closeFactor = ')'
module.delim.openBlock = '{'
module.delim.closeBlock = '}'

--  Separators
module.sep.statement = ';'

--  Keywords
module.kw.return_ = 'return'

module.op.toName = {
  [module.op.add] = 'add',
  [module.op.subtract] = 'subtract',
  [module.op.multiply] = 'multiply',
  [module.op.divide] = 'divide',
  [module.op.modulus] = 'modulus',
  [module.op.exponent] = 'exponent',
  [module.op.less] = 'less',
  [module.op.greater] = 'greater',
  [module.op.lessOrEqual] = 'lessOrEqual',
  [module.op.greaterOrEqual] = 'greaterOrEqual',
  [module.op.equal] = 'equal',
  [module.op.notEqual] = 'notEqual',
}

module.op.unaryToName = {
    [module.op.negate] = 'negate',
}

return module
