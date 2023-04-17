local module = { op = {}, delim = {}, sep = {}, comments = {}  }

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
module.op.unaryNot = '!'

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
    [module.op.unaryNot] = 'not',
}

return module
