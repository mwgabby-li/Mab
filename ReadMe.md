# Final Project Report: Mab

## Language Syntax

INSTRUCTIONS: In this section, describe the overall syntax of your language.

## New Features/Changes

INSTRUCTIONS: In this section, describe the new features or changes that you have added to the programming language. This should include:
* Detailed explanation of each feature/change
* Examples of how they can be used
* Any trade-offs or limitations you are aware of


### Type Specification, Unified Types

In Mab, all variables, including functions, share a unified syntax for type specification.
TODO

### Type Checker/Strongly Typed

Mab uses a type checker and is strongly typed.

Expressions are all recursively evaluated to types, and checked for compatibility between operands and in parts of
statements.

For example, this code will check if `true` is a boolean, because it must be to be the condition of the ternary
operator. It will then check to make sure both arms of the ternary match in type (which they don't!) and then
return the type of the first arm in order to continue checking, whether or not the check passed.

```
:test = true ? 1 : false;
```

Variables are assigned types, or types are inferred from their assignments.
Further type inference is not performed.

Inferred to be a number:
```
:var = 12;
```
Specified as a number, can be assigned a number later:
```
number:var;
var = 15;
```

This is not valid; variables must have a type or an initializer when first created:
```
:var;
var = true;
```

Conditionals only accept expressions that evaluate to booleans:

```
# Valid code
:this is a boolean = true;
if this is a boolean {
    # The type checker is... pleased!
}

# Invalid code, will fail type check phase
:this is a number = 12;
if this is a number {
    # Sadness and tears.
}
```

Boolean operators may only be used with boolean types:
```
:number = 12;
:another number = 15;

# This'll throw an error in the type checker.
:a boolean = number & another number;
```

However, logical operators will cause a type conversion of the expression to a boolean, which will then be acceptable
for conditionals or assignment to booleans:
``` 
a boolean = another number > number;
```

Arrays are also typed in both their number of dimensions and the size of each dimension.
```
# This is valid code.
:array = [2][2] true;
:subarray = [2] false;

# We can assign here because array[1] is a 2-element array of booleans, the same as subarray.
array[1] = subarray;

:mismatched array = [3] true;

# This will fail in the type checker because the array sizes are different:
array[2] = mismatched array;

```

Array types can be specified, which is necessary for functions since the language is strongly typed and has no support
for anything like automatic generics:
```
function matrix:[2][2] number -> boolean:is identity {
    :i = 1;
    while i <= 2 {
        :j = 1;
        while j <= 2 {
            if i = j & matrix[i][j] ~= 1 {
                return false
            }
            elseif i ~= j & matrix[i][j] ~= 0 {
                return false;
            }
        }
    }
    return true;
}
```

But currently redundant and useless for variables:
```
function -> number entry point {
    local [2][2] number:matrix = new[2][2] 0;
    # Same as :matrix = new[2][2] 0;
    
    matrix[1][1] = 1;
    matrix[2][2] = 1;
    return is identity(matrix)
}
```
Notably, array types are required to have initializers because default values are not supported for them,
making type specifiers even more useless.

### Robust Error Support

Error messages indicate the line number, and show it along with surrounding context lines with an indication of the
exact character where the error occurs.

### Booleans

Basic boolean support. The default value of booleans is `false`.

There is intentionally no direct coercion between booleans and numbers,
i.e. `0` is not `false`, and conditionals may only accept booleans.

### Ternary Operator

The ternary operator has the same syntax as the C/C++ version:
`<expression> ? <evaluate if true> : <evaluate if false>`.

### Two-Pass Compilation

Rather than support forward declarations, Mab scans the entire AST up-front and collects all functions before
proceeding.

This is not technically the same as the exercise, but it does allow for indirect recursion.

For example, this is valid Mab code:
```
function -> number: entry point {
  global:n = 10;
  if even() = true {
    return 1
  } else {
    return 0
  }
}
function -> boolean: even {
  if n ~= 0 {
    n = n - 1;
    return odd()
  } else {
    return true
  }
}
function -> boolean: odd {
  if n ~= 0 {
    n = n - 1;
    return even()
  } else {
    return false
  }
}
```
#### Limitations

If I want to support modules, I'll need a new feature.

### More Name Collision Support

The exercises call for detecting collisions between global variables and functions, and parameters with the same name,
and locals in the same scope sharing a name.

In addition to this, I prevent local variables with the same name as functions and parameters with the same name as
functions.

#### Limitations

If a local is given the same name as a global, the global will always be shadowed, even if the global is created *after*
the local, which is a bit odd.

For example, the following function will return 12, rather than generating a type mismatch error:
```
function -> number: entry point {
  local:v = 12;
  global:v = false;

  return v;
}
```

### Numeral Base Notation

Mab indicates a number of a specific with the following format:

`0n<digits>`, where `n` is the last digit in the base. For example, `09 128` is the number 128 in base 10, and `07 200`
is 128 in base 8. `0F 80` is the same number in hexidecimal.

#### Limitations

This syntax can be a bit confusing to those used to other languages, because `0x80` in Mab is 540 in base 10.
128 would be `0x5N` with this prefix, as it indicates base 35 in Mab.

### Single Spaces in Numerals

Mab supports single spaces in numerals for digit grouping. For example, `1 000 000` is valid as a way of writing the
number one million.
This also works with base notation, and in fact the separator between the base prefix and the rest of the number is just
part of this feature.

For example, one might write `0F FF FF 00` to group a 3-byte (24-bit) color, or `01 1000 0110 1111` to write out a
boolean mask in a readable way.

Digit grouping with spaces is supported by many standards organizations.
See, for example, the [22nd General Conference of Weights and Measures Resolution 10](https://www.bipm.org/en/committees/cg/cgpm/22-2003/resolution-10).

Commas and periods are culture-specific and can cause confusion between fractional parts of the number and
digit grouping.

### Single Spaces and Dashes in Identifiers

Mab supports single spaces and dashes in identifiers.
Note that it does not support _whitespace generally_, just single spaces, and the spaces are part of the identifier.
The variables `local:delta x` and `local:deltax` are two different identifiers, and this line of code is a syntax error:
```
local:delta    x = 12;
```

Dashes may only be placed between two other alphanumeric characters in a variable name:
```
# Valid
local:dashed-identifier;

# Invalid:
local:-leading-dash-identifier;

# Invalid:
local:trailing-dash-identifier-;

# Invalid:
local:dash-and- space-identifier;

# Invalid:
local:dash-and -space-identifier;

# Valid:
local:brandywine over-the-water;
```

#### Limitations

There is some ambiguity with the `return` keyword and spaces, as it can be read as an identifier in some cases,
such as `return a = b`, which will be parsed as `return a` `=` `b` rather than `return` `a = b`.
This particular case could also be solved by requiring a different character than equals for assignment,
by disallowing the return keyword as a prefix for variables, or by using a double equals for equality.
The underlying issue is that every statement except for assignment begins with a keyword,
and every statement except for return has a block opening after it.

The block opening is used to prevent confusion in all the other cases and allows for variables to begin with keywords
followed by spaces, such as:
```
:if we win this time;
if we win this time = false;
if if we win this time {
    # Yes, this is pretty confusing, but the language is named after a fairy of dreams and madness, right?
}
```

To avoid another case of ambiguity, a function call as a statement must be proceeded by the `call` keyword.
Because function calls like this can be a sign of mutating program state in unclear ways, I judged that adding some
friction to this case was not much of a negative.

Dashes can also be confused with binary or unary operators. Requiring alphanumeric characters on both sides avoids this
issue in most cases, but I think there are some programmers who would find the need for spaces all the time infuriating.

### Command-Line Options

Mab supports a robust array of command-line options:

`--tests`: Run test suite. Must be first argument.

`--input`/`-i`: Specify input file, relative to working directory.

`--ast`/`-a`: Print the AST.

`--code`/`-c`: Output the generated code.

`--trace`/`-t`: Output an execution trace, with stack state after each instruction.

`--result`/`-r`: Output the result of the program. (The return value from `entry point`.)

`--echo-input`/`-e`: Output what was sent in to translate.

`--graphviz`/`-g`: Generate a graphviz visualization and open it in Firefox. (Unstable.)

`--pegdebug`/`-p`: Annotate the grammar with PegDebug before translating.

`--type-checker-off`/`-y`: Disable the type checker phase. "Damn the torpedoes, full speed ahead!"

## Future

INSTRUCTIONS: 
In this section, discuss the future of your language / DSL, such as how it could be deployed (if applicable), features, etc.

* What would be needed to get this project ready for production?
* How would you extend this project to do something more? Are there other features you’d like? How would you go about adding them?

## Self assessment

INSTRUCTIONS:
* Self assessment of your project: for each criteria described on the final project specs, choose a score (1, 2, 3) and explain your reason for the score in 1-2 sentences.
* Have you gone beyond the base requirements? How so?


### Language Completeness: 3/3
* All exercises have been incorporated into the language, as well as two optional features
(booleans and the ternary operator) and the type checker.
* As reflected in **New Features/Changes**, many changes have been made beyond basic project requirements.

### Code Quality & Report: 3/3

* Code organization is exceptional, with well-named files, organized into directories, and phases numbered by order of 
execution.
* Error handling is user-friendly, with a wide variety of well-written error messages, and in the worst case,
exceptions in phase execution will be caught as internal errors.
* The language includes a suite of test cases.

### Originality & Scope: 3/3
* Solves real-world problem of accidentally defining globals by requiring explicit variable creation and
defaulting to local variables.
* Language is broken into different phases to allow localized changes, and is otherwise modular,
with things like literals defined in a single place for customization.

## References

INSTRUCTIONS:
List any references used in the development of your language besides this courses, including any books, papers, or online resources.

Most of my research beyond asking questions on Discord was small Google searches, but here are some relatively relevant
links.

### [syntax across languages](http://rigaux.org/language-study/syntax-across-languages.html)
I used this to get some ideas for function syntax.

### [OCaml Book: Recursive Functions](https://ocamlbook.org/recursive-functions/#recursive-binding-syntax)
Hugo mentioned OCaml's keywords for recursion, I was curious and looked it up here.

### [GLSL Programming/Vector and Matrix Operations](https://en.m.wikibooks.org/wiki/GLSL_Programming/Vector_and_Matrix_Operations)
This is an example of a language heavily tilted toward vector math.

### [Pattern Matching for InstanceOf](https://bugs.openjdk.org/browse/JDK-8250623)
An interesting bug with a discussion related to type inference.

### [JavaScript: How Line Breaks and Missing Semicolons Can Break Your Code](https://javascript.plainenglish.io/javascript-how-line-breaks-and-missing-semicolons-can-break-your-code-58e031e7f235)
The woes of automatic semicolon insertion in JavaScript.

### [Frink](https://frinklang.org/)
A programming language that does unit checking.

