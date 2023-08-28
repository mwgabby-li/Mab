local module = {}

local errors = {
  ['TYPECHECK INTERNAL UNKNOWN TYPE TAG'] = 'Unknown type tag.',

  ['TYPECHECK PARAMETER ARGUMENT TYPE MISMATCH'] = 'Parameter does not match argument type.',
  
  ['TYPECHECK USING UNDEFINED VARIABLE'] = 'Use of undefined variable.',
  
  ['TYPECHECK NEW ARRAY NON NUMERIC DIMENSION TYPE'] = 'Creating array with dimension of non-number type.',
  
  ['TYPECHECK NEW ARRAYS LITERAL ONLY'] = 'New arrays must be created with literal numbers.',
  
  ['TYPECHECK NON NUMERIC ARRAY INDEX'] = 'Array indexing with invalid type.',
  
  ['TYPECHECK INDEXING NON ARRAY'] = 'Attempting to index into a non-array variable.',
  
  ['TYPECHECK MISMATCHED TYPES WITH OPERATOR'] = 'Mismatched types with operator.',
  
  ['TYPECHECK BINARY OPERATOR INVALID TYPE'] = 'Binary operator cannot be used with type.',
  
  ['TYPECHECK UNARY OPERATOR INVALID TYPE'] = 'Unary operator cannot be used with type.',
  
  ['TYPECHECK TERNARY CONDITION MUST BE BOOLEAN'] = 'Ternary condition must evaluate to boolean.',

  ['TYPECHECK TERNARY BRANCHES TYPE MISMATCH'] = 'Ternary branches have different types.',
  
  ['TYPECHECK INTERNAL UNKNOWN EXPRESSION NODE TAG'] = 'Unknown expression node.',
  
  ['TYPECHECK INTERNAL UNKNOWN SCOPE WHILE INFERRING'] = 'Unknown scope while inferring.',
  
  ['TYPECHECK INTERNAL UNDEFINED SCOPE WHILE INFERRING'] = 'Undefined scope while inferring.',
  
  ['TYPECHECK VARIABLE INIT TYPE MISMATCH'] = 'Variable initialization type mismatch.',
  
  ['TYPECHECK FUNCTION TYPE NO DEFAULT VALUE'] = 'Function type specified but no value provided.',
  
  ['TYPECHECK INVALID TYPE SPECIFIED'] = 'Invalid specified type for variable.',
  
  ['TYPECHECK CANNOT INFER TYPE'] = 'Cannot infer variable type.',
  
  ['TYPECHECK CANNOT INFER TYPE NO ASSIGNMENT'] = 'Cannot determine type with no assignment.',
  
  ['TYPECHECK FUNCTION NAME STARTS WITH CONDITIONAL'] = 'Invalid function prefix.',
  ['TYPECHECK FUNCTION NAME STARTS WITH CONDITIONAL'] = '"{name}" starts with the conditional keyword "{keyword}," and is type "{inferredType}." Function types may not start with conditional keywords, sorry.',
  
  ['TYPECHECK INTERNAL UNKNOWN SCOPE POST INFER'] = 'Unknown scope after infer called.',

  ['TYPECHECK INTERNAL UNDEFINED SCOPE POST INFER'] = 'Undefined scope after infer called.',

  ['TYPECHECK RETURN TYPE UNDETERMINABLE'] = 'Could not determine type of return.',
  
  ['TYPECHECK RETURN TYPE MISMATCH'] = 'Mismatched return types.',

  ['TYPECHECK CANNOT ASSIGN FROM SOURCE WITH INVALID TYPE TO TARGET WITH INVALID TYPE'] = 'Assignment from a source with invalid type.',

  ['TYPECHECK CANNOT ASSIGN FROM EXPRESSION WITH INVALID TYPE TO TARGET WITH INVALID TYPE'] = 'Assignment from expression with invalid type to target with invalid type.',

  ['TYPECHECK CANNOT ASSIGN FROM SOURCE WITH INVALID TYPE'] = 'Assignment from source with invalid type.',

  ['TYPECHECK CANNOT ASSIGN FROM EXPRESSION WITH INVALID TYPE'] = 'Assignment from expression with invalid type.',

  ['TYPECHECK CANNOT ASSIGN TO TARGET WITH INVALID TYPE'] = 'Assignment to target with invalid type.',

  ['TYPECHECK ASSIGNMENT MISMATCHED TYPES'] = 'Assignment source and target have mismatched types.',

  ['TYPECHECK IF CONDITION NOT BOOLEAN'] = 'if statements require a boolean value.',
  
  ['TYPECHECK WHILE CONDITION NOT BOOLEAN'] = 'while loop conditionals require a boolean value.',
  
  ['TYPECHECK EXIT NO RETURN'] = 'Invalid exit with no return value.',
  
  ['TYPECHECK INTERNAL UNKNOWN STATEMENT NODE'] = 'Unknown statement node.',
  
  ['TYPECHECK INVALID TOP LEVEL SCOPE'] = 'Invalid top-level variable scope.',
  
  ['TYPECHECK FUNCTION REDEFINED'] = 'Function redefined with different return type.',
  
  ['TYPECHECK FUNCTION DEFAULT ARG NO PARAMS'] = 'Default argument but no parameters in function.',
  
  ['TYPECHECK FUNCTION DEFAULT ARG TYPE MISMATCH'] = 'Default argument type does not match parameter type.',
  
  ['TYPECHECK ENTRY POINT MUST RETURN NUMBER'] = 'Entry point must return a number.',


  ['STACKVM TRANSLATOR UNDEFINED FUNCTION CALL'] = "Attempted to call an undefined function.",

  ['STACKVM TRANSLATOR FUNCTION PARAMETER MISMATCH'] = "Function called with incorrect number of arguments.",

  ['STACKVM TRANSLATOR UNDEFINED VARIABLE'] = "Attempted to access an undefined variable.",

  ['STACKVM TRANSLATOR ARRAY SIZE NOT LITERAL'] = "New array sizes must be literal numbers.",

  ['STACKVM TRANSLATOR UNKNOWN EXPRESSION NODE'] = "Unknown type of expression encountered.",

  ['STACKVM TRANSLATOR VARIABLE ALREADY DEFINED'] = "Variable already defined in this scope.",

  ['STACKVM TRANSLATOR REDEFINING GLOBAL VARIABLE'] = "Global variable redefined.",

  ['STACKVM TRANSLATOR INTERNAL UNDEFINED SCOPE'] = "Internal error: Scope undefined.",

  ['STACKVM TRANSLATOR ARRAY DEFAULT REQUIRED'] = "Default values required for array types.",

  ['STACKVM TRANSLATOR VARIABLE NO TYPE'] = "Variable declared without a type.",

  ['STACKVM TRANSLATOR INTERNAL UNKNOWN SCOPE'] = "Internal error: Unknown scope.",

  ['STACKVM TRANSLATOR INTERNAL SCOPE UNDEFINED'] = "Internal error: Scope undefined.",

  ['STACKVM TRANSLATOR ASSIGN UNDEFINED VARIABLE'] = "Assigning to an undefined variable.",

  ['STACKVM TRANSLATOR UNKNOWN WRITE TARGET TYPE'] = "Unknown write target type encountered.",

  ['STACKVM TRANSLATOR INTERNAL UNKNOWN STATEMENT NODE'] = "Internal error: Unknown statement node.",

  ['STACKVM TRANSLATOR DUPLICATE FUNCTION PARAMETER'] = "Function has duplicate instances of the same parameter.",

  ['STACKVM TRANSLATOR TODO DEFAULT ARRAY RETURN'] = "Returning default array type not supported.",

  ['STACKVM TRANSLATOR INTERNAL UNKNOWN TYPE'] = "Internal error: Unknown type.",

  ['STACKVM TRANSLATOR NO ENTRY POINT'] = "No entry point found in the program.",

  ['STACKVM TRANSLATOR ENTRY POINT PARAMETER MISMATCH'] = "Entry point function should not have parameters.",
  
  ['STACKVM TRANSLATOR DUPLICATE TOP-LEVEL VARIABLES'] = 'Multiple top-level variables sharing the same name.',

  ['STACKVM TRANSLATOR INTERNAL UNHANDLED TAG'] = "Internal error: Unhandled tag at top level.",
  
  
  ['GRAPHVIZ TRANSLATOR UNKNOWN EXPRESSION NODE TAG'] = 'Graphviz translator encountered an unknown expression node tag.',
  
  ['GRAPHVIZ TRANSLATOR UNKNOWN STATEMENT NODE TAG'] = 'Graphviz translator encountered an unknown statement node tag.',
  
  
  ['STACKVM INTERPRETER ARRAY INDEX OUT OF RANGE ON GET'] = 'Array index out-of-range when getting value.',
  
  ['STACKVM INTERPRETER ARRAY INDEX OUT OF RANGE ON SET'] = 'Array index out-of-range when setting value.',

  ['STACKVM INTERPRETER EMPTY PROGRAM'] = 'Stack VM was sent empty program.',
  
  ['STACKVM INTERPRETER UNKNOWN INSTRUCTION'] = 'Stack VM interpreter encountered an unknown instruction.',

  ['STACKVM INTERPRETER INCORRECT STACK COUNT ON EXIT'] = 'Stack VM interpreter reported incorrect stack size on exit.',
  
  
  ['PCALL CATCH'] = 'Internal error caught by pcall.',
}

local errorMessages = {
  ['TYPECHECK INTERNAL UNKNOWN TYPE TAG'] = 'Internal error: Unknown type tag "{typeTag}"',

  ['TYPECHECK PARAMETER ARGUMENT TYPE MISMATCH'] = 'Argument {number} to function called via "{rootName}" evaluates to type "{argumentType}," but parameter "{parameterName}" is type "{parameterType}."',

  ['TYPECHECK USING UNDEFINED VARIABLE'] = 'Attempting to use undefined variable "{name}."',

  ['TYPECHECK NEW ARRAY NON NUMERIC DIMENSION TYPE'] = 'Creating a new array with dimension of type "{sizeType}", only "number" is allowed. Sorry!',

  ['TYPECHECK NEW ARRAYS LITERAL ONLY'] = 'New arrays must be created with literal numbers. Sorry!',

  ['TYPECHECK NON NUMERIC ARRAY INDEX'] = 'Array indexing with type "{indexType}", only "number" is allowed. Sorry!',

  ['TYPECHECK INDEXING NON ARRAY'] = 'Attempting to index into "{variableName}", which is a "{arrayType}", not an array.',

  ['TYPECHECK MISMATCHED TYPES WITH OPERATOR'] = 'Mismatched types with operator "{operator}"! ({firstChildType} {operator} {secondChildType}).',

  ['TYPECHECK BINARY OPERATOR INVALID TYPE'] = 'Binary operator "{operator}" cannot be used with type "{expressionType}."',

  ['TYPECHECK UNARY OPERATOR INVALID TYPE'] = 'Unary operator "{operator}" cannot be used with type "{childType}."',

  ['TYPECHECK TERNARY CONDITION MUST BE BOOLEAN'] = 'Ternary condition expression must evaluate to boolean. This expression evaluates to "{testType}."',

  ['TYPECHECK TERNARY BRANCHES TYPE MISMATCH'] = 'The two branches of the ternary operator must have the same type. Currently, the type of the true branch is "{trueBranchType}", and the type of the false branch is "{falseBranchType}."',

  ['TYPECHECK INTERNAL UNKNOWN EXPRESSION NODE TAG'] = 'Internal error: Unknown expression node tag "{tag}"',

  ['TYPECHECK INTERNAL UNKNOWN SCOPE WHILE INFERRING'] = 'Internal error: Unknown scope "{scope}" while inferring scope.',

  ['TYPECHECK INTERNAL UNDEFINED SCOPE WHILE INFERRING'] = 'Internal error: Undefined scope while inferring scope.',

  ['TYPECHECK VARIABLE INIT TYPE MISMATCH'] = 'Type of variable is "{specifiedType}" but variable is being initialized with "{assignmentType}."',

  ['TYPECHECK FUNCTION TYPE NO DEFAULT VALUE'] = 'Function type specified for variable "{name}", but no value was provided. Defaults required for functions, sorry!',

  ['TYPECHECK INVALID TYPE SPECIFIED'] = 'Type of variable "{name}" specified, but type is invalid: "{specifiedType}."',

  ['TYPECHECK CANNOT INFER TYPE'] = 'Cannot determine type of variable "{name}" because no type was specified and the assignment has no type.',

  ['TYPECHECK CANNOT INFER TYPE NO ASSIGNMENT'] = 'Cannot determine type of variable "{name}" because no type was specified and no assignment was made.',

  ['TYPECHECK FUNCTION NAME STARTS WITH CONDITIONAL'] = '"{name}" starts with the conditional keyword "{keyword}," and is type "{inferredType}." Function types may not start with conditional keywords, sorry.',

  ['TYPECHECK INTERNAL UNKNOWN SCOPE POST INFER'] = 'Internal error: Unknown scope {scope} after infer called. Could not assign inferred type because the scope of "{variableName}" was not inferred.',

  ['TYPECHECK INTERNAL UNDEFINED SCOPE POST INFER'] = 'Internal error: Scope undefined after infer called. Could not assign inferred type because the scope of "{variableName}" was not inferred.',

  ['TYPECHECK RETURN TYPE UNDETERMINABLE'] = 'Could not determine type of return type.',

  ['TYPECHECK RETURN TYPE MISMATCH'] = 'Mismatched types with return, function "{functionName}" returns "{expectedReturnType}", but returning type "{actualReturnType}".',

  ['TYPECHECK CANNOT ASSIGN FROM SOURCE WITH INVALID TYPE TO TARGET WITH INVALID TYPE'] = 'Sorry, cannot assign from "{expressionRootName}," because its type is invalid: "{expressionType}."\n The invalid type of "{targetRootName}" the assignment target, also prevents this: "{targetType}."',

  ['TYPECHECK CANNOT ASSIGN FROM EXPRESSION WITH INVALID TYPE TO TARGET WITH INVALID TYPE'] =  'Sorry, cannot assign from invalid type: "{expressionType}."\n The invalid type of "{targetRootName}" the assignment target, also prevents this: "{targetType}."',

  ['TYPECHECK CANNOT ASSIGN FROM SOURCE WITH INVALID TYPE'] = 'Sorry, cannot assign from "{expressionRootName}," because its type is invalid: "{expressionType}."',

  ['TYPECHECK CANNOT ASSIGN FROM EXPRESSION WITH INVALID TYPE'] = 'Sorry, cannot assign from an invalid type: "{expressionType}."',

  ['TYPECHECK CANNOT ASSIGN TO TARGET WITH INVALID TYPE'] = 'Sorry, cannot assign to "{targetRootName}" because its type is invalid: "{targetType}."',

  ['TYPECHECK ASSIGNMENT MISMATCHED TYPES'] = 'Assigning from "{fromType}" to "{toType}". Disallowed, sorry!',

  ['TYPECHECK IF CONDITION NOT BOOLEAN'] = 'if statements require a boolean value, or an expression evaluating to a boolean. Type was "{type}".',

  ['TYPECHECK WHILE CONDITION NOT BOOLEAN'] = 'while loop conditionals require a boolean value, or an expression evaluating to a boolean. Type was "{type}".',

  ['TYPECHECK EXIT NO RETURN'] = 'Requested exit with no return value (with \'exit\' keyword), but function\'s result type is "{type}", not "none."',

  ['TYPECHECK INTERNAL UNKNOWN STATEMENT NODE'] = 'Internal error: Unknown statement node tag "{tag}".',

  ['TYPECHECK INVALID TOP LEVEL SCOPE'] = 'Top-level variables cannot use any scope besides global, which is the default. Otherwise, they would be inaccessible.',

  ['TYPECHECK FUNCTION REDEFINED'] = 'Function "{name}" redefined returning type "{newType}", was "{oldType}".',

  ['TYPECHECK FUNCTION DEFAULT ARG NO PARAMS'] = 'Function "{name}" has a default argument but no parameters.',

  ['TYPECHECK FUNCTION DEFAULT ARG TYPE MISMATCH'] = 'Default argument for function "{name}" evaluates to type "{defaultArgType}", but parameter "{parameterName}" is type "{parameterType}".',

  ['TYPECHECK ENTRY POINT MUST RETURN NUMBER'] = 'Entry point must return a number because that\'s what OSes expect.',

  ['STACKVM TRANSLATOR UNDEFINED FUNCTION CALL'] = 'Cannot call function, "{funcName}" is undefined.',

  ['STACKVM TRANSLATOR FUNCTION PARAMETER MISMATCH'] = 'Function "{funcName}" has {paramCount} but was sent {argCount}.',

  ['STACKVM TRANSLATOR UNDEFINED VARIABLE'] = 'Trying to load from undefined variable "{varName}".',

  ['STACKVM TRANSLATOR ARRAY SIZE NOT LITERAL'] = 'New array sizes must be literal numbers.',

  ['STACKVM TRANSLATOR UNKNOWN EXPRESSION NODE'] = 'Unknown expression node tag "{tag}".',

  ['STACKVM TRANSLATOR VARIABLE ALREADY DEFINED'] = 'Variable "{varName}" already defined in this scope.',

  ['STACKVM TRANSLATOR REDEFINING GLOBAL VARIABLE'] = 'Re-defining global variable "{varName}".',

  ['STACKVM TRANSLATOR INTERNAL UNDEFINED SCOPE'] = 'Internal error: Scope undefined.',

  ['STACKVM TRANSLATOR ARRAY DEFAULT REQUIRED'] = 'Default values required for array types. To-Do: Allow this! For now, add a default value to: "{varName}".',

  ['STACKVM TRANSLATOR VARIABLE NO TYPE'] = 'No type for variable "{varName}".',

  ['STACKVM TRANSLATOR INTERNAL UNKNOWN SCOPE'] = 'Internal error: Unknown scope "{scope}".',

  ['STACKVM TRANSLATOR INTERNAL SCOPE UNDEFINED'] = 'Internal error: Scope undefined.',

  ['STACKVM TRANSLATOR ASSIGN UNDEFINED VARIABLE'] = 'Assigning to undefined variable "{targetName}".',

  ['STACKVM TRANSLATOR UNKNOWN WRITE TARGET TYPE'] = 'Unknown write target type, tag was "{tag}".',

  ['STACKVM TRANSLATOR INTERNAL UNKNOWN STATEMENT NODE'] = 'Internal error: Unknown statement node tag "{tag}".',

  ['STACKVM TRANSLATOR DUPLICATE FUNCTION PARAMETER'] = 'Function "{funcName}" has {paramCount} instances of the parameter "{paramName}".',

  ['STACKVM TRANSLATOR TODO DEFAULT ARRAY RETURN'] = 'TODO: Returning default array type not supported, add an explicit return to: "{funcName}".',

  ['STACKVM TRANSLATOR INTERNAL UNKNOWN TYPE'] = 'Internal error: unknown type "{typeTag}" when generating automatic return value.',

  ['STACKVM TRANSLATOR NO ENTRY POINT'] = 'No entry point found. (Program must contain a function named "entry point.")',

  ['STACKVM TRANSLATOR ENTRY POINT PARAMETER MISMATCH'] = 'Entry point has {paramCount} but should have none.',

  ['STACKVM TRANSLATOR DUPLICATE TOP-LEVEL VARIABLES'] = 'Found {duplicateCount} duplicate top-level variables sharing name "{name}."',

  ['STACKVM TRANSLATOR INTERNAL UNHANDLED TAG'] = 'Internal error: Unhandled tag "{tag}" at top level. Ignoring...',
  
  
  ['GRAPHVIZ TRANSLATOR UNKNOWN EXPRESSION NODE TAG'] = 'Unknown expression node tag "{tag}."',

  ['GRAPHVIZ TRANSLATOR UNKNOWN STATEMENT NODE TAG'] = 'Unknown statement node tag "{tag}."',


  ['STACKVM INTERPRETER ARRAY INDEX OUT OF RANGE ON GET'] = 'Out of range when getting value from array. Array is size {size} but indexed at {index}.',

  ['STACKVM INTERPRETER ARRAY INDEX OUT OF RANGE ON SET'] = 'Out of range when setting value in array. Array is size {size} but indexed at {index}.',

  ['STACKVM INTERPRETER EMPTY PROGRAM'] = 'Empty program. Aborting...',
  
  ['STACKVM INTERPRETER UNKNOWN INSTRUCTION'] = 'Unknown instruction "{code}."',

  ['STACKVM INTERPRETER INCORRECT STACK COUNT ON EXIT'] = 'Internal error: Expected stack count of one at the end of the program, but stack count is {count}.',


  ['PCALL CATCH'] = 'Internal error caught by pcall: "{message}"',
}

function module.get(key)
  return text[key]
end

function module.getError(key)
  return errors[key]
end

function module.getErrorMessage(key)
  return errorMessages[key]
end

return module
