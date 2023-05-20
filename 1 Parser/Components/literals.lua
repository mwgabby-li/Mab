local module = { op = {}, delim = {}, sep = {}, comments = {}  }

-- Language literals, they can be customized here.
--  Operators
module.op.assign = '=' -- Assign is a special case. It's a statement operator.
module.op.print = '@'  -- Same with print.

-- Literals for binary operators
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
module.op.equal = '='
module.op.notEqual = '~='
module.op.and_ = '&'
module.op.or_ = '|'
module.op.ternary = '?'
module.op.ternaryBranch = ':'

-- Literals for unary operators
module.op.not_ = '!'
module.op.positive = '+'
module.op.negate = '-'

--  Comments
module.comments.startLine = '#'
module.comments.openBlock = '#{'
module.comments.closeBlock = '#}'

--  Delimiters
module.delim.openArray = '['
module.delim.closeArray = ']'
module.delim.openFactor = '('
module.delim.closeFactor = ')'
module.delim.openBlock = '{'
module.delim.closeBlock = '}'
module.delim.openFunctionParameterList = '('
module.delim.closeFunctionParameterList = ')'

--  Separators
module.sep.statement = ';'
module.sep.newVariable = ':'
module.sep.parameter = ':'
module.sep.returnResult = ':'
module.sep.argument = ','
module.sep.functionResult = '->'

module.entryPointName = 'entry point'

return module
