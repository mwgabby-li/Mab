local module = {}

local errors = {
  ['ERROR TYPECHECK INTERNAL UNKNOWN TYPE TAG'] = 'Unknown type tag.',
  ['ERROR TYPECHECK INTERNAL UNKNOWN TYPE TAG MESSAGE'] = 'Internal error: Unknown type tag "{typeTag}"',

  ['ERROR TYPECHECK PARAMETER ARGUMENT TYPE MISMATCH'] = 'Parameter does not match argument type.',
  ['ERROR TYPECHECK PARAMETER ARGUMENT TYPE MISMATCH MESSAGE'] = 'Argument {number} to function called via "{rootName}" evaluates to type "{argumentType}," but parameter "{parameterName}" is type "{parameterType}."',
  
  ['ERROR TYPECHECK USING UNDEFINED VARIABLE'] = 'Use of undefined variable.',
  ['ERROR TYPECHECK USING UNDEFINED VARIABLE MESSAGE'] = 'Attempting to use undefined variable "{name}."',
  
  ['ERROR TYPECHECK NEW ARRAY NON NUMERIC DIMENSION TYPE'] = 'Creating array with dimension of non-number type.',
  ['ERROR TYPECHECK NEW ARRAY NON NUMERIC DIMENSION TYPE MESSAGE'] = 'Creating a new array with dimension of type "{sizeType}", only "number" is allowed. Sorry!',
  
  ['ERROR TYPECHECK NEW ARRAYS LITERAL ONLY'] = 'New arrays must be created with literal numbers.',
  ['ERROR TYPECHECK NEW ARRAYS LITERAL ONLY MESSAGE'] = 'New arrays must be created with literal numbers. Sorry!',
  
  ['ERROR TYPECHECK NON NUMERIC ARRAY INDEX'] = 'Array indexing with invalid type.',
  ['ERROR TYPECHECK NON NUMERIC ARRAY INDEX MESSAGE'] = 'Array indexing with type "{indexType}", only "number" is allowed. Sorry!',
  
  ['ERROR TYPECHECK INDEXING NON ARRAY'] = 'Attempting to index into a non-array variable.',
  ['ERROR TYPECHECK INDEXING NON ARRAY MESSAGE'] = 'Attempting to index into "{variableName}", which is a "{arrayType}", not an array.',
  
  ['ERROR TYPECHECK MISMATCHED TYPES WITH OPERATOR'] = 'Mismatched types with operator.',
  ['ERROR TYPECHECK MISMATCHED TYPES WITH OPERATOR MESSAGE'] = 'Mismatched types with operator "{operator}"! ({firstChildType} {operator} {secondChildType}).',
  
  ['ERROR TYPECHECK BINARY OPERATOR INVALID TYPE'] = 'Binary operator cannot be used with type.',
  ['ERROR TYPECHECK BINARY OPERATOR INVALID TYPE MESSAGE'] = 'Binary operator "{operator}" cannot be used with type "{expressionType}."',
  
  ['ERROR TYPECHECK UNARY OPERATOR INVALID TYPE'] = 'Unary operator cannot be used with type.',
  ['ERROR TYPECHECK UNARY OPERATOR INVALID TYPE MESSAGE'] = 'Unary operator "{operator}" cannot be used with type "{childType}."',
  
  ['ERROR TYPECHECK TERNARY CONDITION MUST BE BOOLEAN'] = 'Ternary condition must evaluate to boolean.',
  ['ERROR TYPECHECK TERNARY CONDITION MUST BE BOOLEAN MESSAGE'] = 'Ternary condition expression must evaluate to boolean. This expression evaluates to "{testType}."',

  ['ERROR TYPECHECK TERNARY BRANCHES TYPE MISMATCH'] = 'Ternary branches have different types.',
  ['ERROR TYPECHECK TERNARY BRANCHES TYPE MISMATCH MESSAGE'] = 'The two branches of the ternary operator must have the same type. Currently, the type of the true branch is "{trueBranchType}", and the type of the false branch is "{falseBranchType}."',
  
  ['ERROR TYPECHECK INTERNAL UNKNOWN EXPRESSION NODE TAG'] = 'Unknown expression node.',
  ['ERROR TYPECHECK INTERNAL UNKNOWN EXPRESSION NODE TAG MESSAGE'] = 'Internal error: Unknown expression node tag "{tag}"',
  
  ['ERROR TYPECHECK INTERNAL UNKNOWN SCOPE WHILE INFERRING'] = 'Unknown scope while inferring.',
  ['ERROR TYPECHECK INTERNAL UNKNOWN SCOPE WHILE INFERRING MESSAGE'] = 'Internal error: Unknown scope "{scope}" while inferring scope.',
  
  ['ERROR TYPECHECK INTERNAL UNDEFINED SCOPE WHILE INFERRING'] = 'Undefined scope while inferring.',
  ['ERROR TYPECHECK INTERNAL UNDEFINED SCOPE WHILE INFERRING MESSAGE'] = 'Internal error: Undefined scope while inferring scope.',
  
  ['ERROR TYPECHECK VARIABLE INIT TYPE MISMATCH'] = 'Variable initialization type mismatch.',
  ['ERROR TYPECHECK VARIABLE INIT TYPE MISMATCH MESSAGE'] = 'Type of variable is "{specifiedType}" but variable is being initialized with "{assignmentType}."',
  
  ['ERROR TYPECHECK FUNCTION TYPE NO DEFAULT VALUE'] = 'Function type specified but no value provided.',
  ['ERROR TYPECHECK FUNCTION TYPE NO DEFAULT VALUE MESSAGE'] = 'Function type specified for variable "{name}", but no value was provided. Defaults required for functions, sorry!',
  
  ['ERROR TYPECHECK INVALID TYPE SPECIFIED'] = 'Invalid specified type for variable.',
  ['ERROR TYPECHECK INVALID TYPE SPECIFIED MESSAGE'] = 'Type of variable "{name}" specified, but type is invalid: "{specifiedType}."',
  
  ['ERROR TYPECHECK CANNOT INFER TYPE'] = 'Cannot infer variable type.',
  ['ERROR TYPECHECK CANNOT INFER TYPE MESSAGE'] = 'Cannot determine type of variable "{name}" because no type was specified and the assignment has no type.',
  
  ['ERROR TYPECHECK CANNOT INFER TYPE NO ASSIGNMENT'] = 'Cannot determine type with no assignment.',
  ['ERROR TYPECHECK CANNOT INFER TYPE NO ASSIGNMENT MESSAGE'] = 'Cannot determine type of variable "{name}" because no type was specified and no assignment was made.',
  
  ['ERROR TYPECHECK FUNCTION NAME STARTS WITH CONDITIONAL'] = 'Invalid function prefix.',
  ['ERROR TYPECHECK FUNCTION NAME STARTS WITH CONDITIONAL'] = '"{name}" starts with the conditional keyword "{keyword}," and is type "{inferredType}." Function types may not start with conditional keywords, sorry.',
  
  ['ERROR TYPECHECK INTERNAL UNKNOWN SCOPE POST INFER'] = 'Unknown scope after infer called.',
  ['ERROR TYPECHECK INTERNAL UNKNOWN SCOPE POST INFER MESSAGE'] = 'Internal error: Unknown scope {scope} after infer called. Could not assign inferred type because the scope of "{variableName}" was not inferred.',

  ['ERROR TYPECHECK INTERNAL UNDEFINED SCOPE POST INFER'] = 'Undefined scope after infer called.',
  ['ERROR TYPECHECK INTERNAL UNDEFINED SCOPE POST INFER MESSAGE'] = 'Internal error: Scope undefined after infer called. Could not assign inferred type because the scope of "{variableName}" was not inferred.',

  ['ERROR TYPECHECK RETURN TYPE UNDETERMINABLE'] = 'Could not determine type of return.',
  ['ERROR TYPECHECK RETURN TYPE UNDETERMINABLE MESSAGE'] = 'Could not determine type of return type.',
  
  ['ERROR TYPECHECK RETURN TYPE MISMATCH'] = 'Mismatched return types.',
  ['ERROR TYPECHECK RETURN TYPE MISMATCH MESSAGE'] = 'Mismatched types with return, function "{functionName}" returns "{expectedReturnType}", but returning type "{actualReturnType}".',

  ['ERROR TYPECHECK CANNOT ASSIGN FROM SOURCE WITH INVALID TYPE TO TARGET WITH INVALID TYPE'] = 'Assignment from a source with invalid type.',
  ['ERROR TYPECHECK CANNOT ASSIGN FROM SOURCE WITH INVALID TYPE TO TARGET WITH INVALID TYPE MESSAGE'] = 'Sorry, cannot assign from "{expressionRootName}," because its type is invalid: "{expressionType}."\n The invalid type of "{targetRootName}" the assignment target, also prevents this: "{targetType}."',

  ['ERROR TYPECHECK CANNOT ASSIGN FROM EXPRESSION WITH INVALID TYPE TO TARGET WITH INVALID TYPE'] = 'Assignment from expression with invalid type to target with invalid type.',
  ['ERROR TYPECHECK CANNOT ASSIGN FROM EXPRESSION WITH INVALID TYPE TO TARGET WITH INVALID TYPE MESSAGE'] =  'Sorry, cannot assign from invalid type: "{expressionType}."\n The invalid type of "{targetRootName}" the assignment target, also prevents this: "{targetType}."',

  ['ERROR TYPECHECK CANNOT ASSIGN FROM SOURCE WITH INVALID TYPE'] = 'Assignment from source with invalid type.',
  ['ERROR TYPECHECK CANNOT ASSIGN FROM SOURCE WITH INVALID TYPE MESSAGE'] = 'Sorry, cannot assign from "{expressionRootName}," because its type is invalid: "{expressionType}."',

  ['ERROR TYPECHECK CANNOT ASSIGN FROM EXPRESSION WITH INVALID TYPE'] = 'Assignment from expression with invalid type.',
  ['ERROR TYPECHECK CANNOT ASSIGN FROM EXPRESSION WITH INVALID TYPE MESSAGE'] = 'Sorry, cannot assign from an invalid type: "{expressionType}."',

  ['ERROR TYPECHECK CANNOT ASSIGN TO TARGET WITH INVALID TYPE'] = 'Assignment to target with invalid type.',
  ['ERROR TYPECHECK CANNOT ASSIGN TO TARGET WITH INVALID TYPE MESSAGE'] = 'Sorry, cannot assign to "{targetRootName}" because its type is invalid: "{targetType}."',

  ['ERROR TYPECHECK ASSIGNMENT MISMATCHED TYPES'] = 'Assignment source and target have mismatched types.',
  ['ERROR TYPECHECK ASSIGNMENT MISMATCHED TYPES MESSAGE'] = 'Assigning from "{fromType}" to "{toType}". Disallowed, sorry!',

  ['ERROR TYPECHECK IF CONDITION NOT BOOLEAN'] = 'if statements require a boolean value.',
  ['ERROR TYPECHECK IF CONDITION NOT BOOLEAN MESSAGE'] = 'if statements require a boolean value, or an expression evaluating to a boolean. Type was "{type}".',
  
  ['ERROR TYPECHECK WHILE CONDITION NOT BOOLEAN'] = 'while loop conditionals require a boolean value.',
  ['ERROR TYPECHECK WHILE CONDITION NOT BOOLEAN MESSAGE'] = 'while loop conditionals require a boolean value, or an expression evaluating to a boolean. Type was "{type}".',
  
  ['ERROR TYPECHECK EXIT NO RETURN'] = 'Invalid exit with no return value.',
  ['ERROR TYPECHECK EXIT NO RETURN MESSAGE'] = 'Requested exit with no return value (with \'exit\' keyword), but function\'s result type is "{type}", not "none."',
  
  ['ERROR TYPECHECK INTERNAL UNKNOWN STATEMENT NODE'] = 'Unknown statement node.',
  ['ERROR TYPECHECK INTERNAL UNKNOWN STATEMENT NODE MESSAGE'] = 'Internal error: Unknown statement node tag "{tag}".',
  
  ['ERROR TYPECHECK INVALID TOP LEVEL SCOPE'] = 'Invalid top-level variable scope.',
  ['ERROR TYPECHECK INVALID TOP LEVEL SCOPE MESSAGE'] = 'Top-level variables cannot use any scope besides global, which is the default. Otherwise, they would be inaccessible.',
  
  ['ERROR TYPECHECK FUNCTION REDEFINED'] = 'Function redefined with different return type.',
  ['ERROR TYPECHECK FUNCTION REDEFINED MESSAGE'] = 'Function "{name}" redefined returning type "{newType}", was "{oldType}".',
  
  ['ERROR TYPECHECK FUNCTION DEFAULT ARG NO PARAMS'] = 'Default argument but no parameters in function.',
  ['ERROR TYPECHECK FUNCTION DEFAULT ARG NO PARAMS MESSAGE'] = 'Function "{name}" has a default argument but no parameters.',
  
  ['ERROR TYPECHECK FUNCTION DEFAULT ARG TYPE MISMATCH'] = 'Default argument type does not match parameter type.',
  ['ERROR TYPECHECK FUNCTION DEFAULT ARG TYPE MISMATCH MESSAGE'] = 'Default argument for function "{name}" evaluates to type "{defaultArgType}", but parameter "{parameterName}" is type "{parameterType}".',
  
  ['ERROR TYPECHECK ENTRY POINT MUST RETURN NUMBER'] = 'Entry point must return a number.',
  ['ERROR TYPECHECK ENTRY POINT MUST RETURN NUMBER MESSAGE'] = 'Entry point must return a number because that\'s what OSes expect.',


  ['ERROR STACKVM TRANSLATOR UNDEFINED FUNCTION CALL'] = "Attempted to call an undefined function.",
  ['ERROR STACKVM TRANSLATOR UNDEFINED FUNCTION CALL MESSAGE'] = 'Cannot call function, "{funcName}" is undefined.',

  ['ERROR STACKVM TRANSLATOR FUNCTION PARAMETER MISMATCH'] = "Function called with incorrect number of arguments.",
  ['ERROR STACKVM TRANSLATOR FUNCTION PARAMETER MISMATCH MESSAGE'] = 'Function "{funcName}" has {paramCount} but was sent {argCount}.',

  ['ERROR STACKVM TRANSLATOR UNDEFINED VARIABLE'] = "Attempted to access an undefined variable.",
  ['ERROR STACKVM TRANSLATOR UNDEFINED VARIABLE MESSAGE'] = 'Trying to load from undefined variable "{varName}".',

  ['ERROR STACKVM TRANSLATOR ARRAY SIZE NOT LITERAL'] = "New array sizes must be literal numbers.",
  ['ERROR STACKVM TRANSLATOR ARRAY SIZE NOT LITERAL MESSAGE'] = 'New array sizes must be literal numbers.',

  ['ERROR STACKVM TRANSLATOR UNKNOWN EXPRESSION NODE'] = "Unknown type of expression encountered.",
  ['ERROR STACKVM TRANSLATOR UNKNOWN EXPRESSION NODE MESSAGE'] = 'Unknown expression node tag "{tag}".',

  ['ERROR STACKVM TRANSLATOR VARIABLE ALREADY DEFINED'] = "Variable already defined in this scope.",
  ['ERROR STACKVM TRANSLATOR VARIABLE ALREADY DEFINED MESSAGE'] = 'Variable "{varName}" already defined in this scope.',

  ['ERROR STACKVM TRANSLATOR REDEFINING GLOBAL VARIABLE'] = "Global variable redefined.",
  ['ERROR STACKVM TRANSLATOR REDEFINING GLOBAL VARIABLE MESSAGE'] = 'Re-defining global variable "{varName}".',

  ['ERROR STACKVM TRANSLATOR INTERNAL UNDEFINED SCOPE'] = "Internal error: Scope undefined.",
  ['ERROR STACKVM TRANSLATOR INTERNAL UNDEFINED SCOPE MESSAGE'] = 'Internal error: Scope undefined.',

  ['ERROR STACKVM TRANSLATOR ARRAY DEFAULT REQUIRED'] = "Default values required for array types.",
  ['ERROR STACKVM TRANSLATOR ARRAY DEFAULT REQUIRED MESSAGE'] = 'Default values required for array types. To-Do: Allow this! For now, add a default value to: "{varName}".',

  ['ERROR STACKVM TRANSLATOR VARIABLE NO TYPE'] = "Variable declared without a type.",
  ['ERROR STACKVM TRANSLATOR VARIABLE NO TYPE MESSAGE'] = 'No type for variable "{varName}".',

  ['ERROR STACKVM TRANSLATOR INTERNAL UNKNOWN SCOPE'] = "Internal error: Unknown scope.",
  ['ERROR STACKVM TRANSLATOR INTERNAL UNKNOWN SCOPE MESSAGE'] = 'Internal error: Unknown scope "{scope}".',

  ['ERROR STACKVM TRANSLATOR INTERNAL SCOPE UNDEFINED'] = "Internal error: Scope undefined.",
  ['ERROR STACKVM TRANSLATOR INTERNAL SCOPE UNDEFINED MESSAGE'] = 'Internal error: Scope undefined.',

  ['ERROR STACKVM TRANSLATOR ASSIGN UNDEFINED VARIABLE'] = "Assigning to an undefined variable.",
  ['ERROR STACKVM TRANSLATOR ASSIGN UNDEFINED VARIABLE MESSAGE'] = 'Assigning to undefined variable "{targetName}".',

  ['ERROR STACKVM TRANSLATOR UNKNOWN WRITE TARGET TYPE'] = "Unknown write target type encountered.",
  ['ERROR STACKVM TRANSLATOR UNKNOWN WRITE TARGET TYPE MESSAGE'] = 'Unknown write target type, tag was "{tag}".',

  ['ERROR STACKVM TRANSLATOR INTERNAL UNKNOWN STATEMENT NODE'] = "Internal error: Unknown statement node.",
  ['ERROR STACKVM TRANSLATOR INTERNAL UNKNOWN STATEMENT NODE MESSAGE'] = 'Internal error: Unknown statement node tag "{tag}".',

  ['ERROR STACKVM TRANSLATOR DUPLICATE FUNCTION PARAMETER'] = "Function has duplicate instances of the same parameter.",
  ['ERROR STACKVM TRANSLATOR DUPLICATE FUNCTION PARAMETER MESSAGE'] = 'Function "{funcName}" has {paramCount} instances of the parameter "{paramName}".',

  ['ERROR STACKVM TRANSLATOR TODO DEFAULT ARRAY RETURN'] = "Returning default array type not supported.",
  ['ERROR STACKVM TRANSLATOR TODO DEFAULT ARRAY RETURN MESSAGE'] = 'TODO: Returning default array type not supported, add an explicit return to: "{funcName}".',

  ['ERROR STACKVM TRANSLATOR INTERNAL UNKNOWN TYPE'] = "Internal error: Unknown type.",
  ['ERROR STACKVM TRANSLATOR INTERNAL UNKNOWN TYPE MESSAGE'] = 'Internal error: unknown type "{typeTag}" when generating automatic return value.',

  ['ERROR STACKVM TRANSLATOR NO ENTRY POINT'] = "No entry point found in the program.",
  ['ERROR STACKVM TRANSLATOR NO ENTRY POINT MESSAGE'] = 'No entry point found. (Program must contain a function named "entry point.")',

  ['ERROR STACKVM TRANSLATOR ENTRY POINT PARAMETER MISMATCH'] = "Entry point function should not have parameters.",
  ['ERROR STACKVM TRANSLATOR ENTRY POINT PARAMETER MISMATCH MESSAGE'] = 'Entry point has {paramCount} but should have none.',

  ['ERROR STACKVM TRANSLATOR INTERNAL UNHANDLED TAG'] = "Internal error: Unhandled tag at top level.",
  ['ERROR STACKVM TRANSLATOR INTERNAL UNHANDLED TAG MESSAGE'] = 'Internal error: Unhandled tag "{tag}" at top level. Ignoring...',

  ['INTERNAL ERROR PREFIX'] = 'Internal error: ',
}

function module.get(key)
  return strings[key]
end

return module
