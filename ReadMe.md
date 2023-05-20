# Final Project Report: Mab

## Language Syntax

### Note on Grammar Notation
The grammar examples are in Extended Backus-Naur Form,
[as described here](https://en.wikipedia.org/w/index.php?title=Extended_Backus%E2%80%93Naur_form&oldid=1152630785).

### Identifiers

In Mab, identifiers may not start with digits, but are allowed to contain the letters
`A`-`Z`, `a`-`z`, the digits `0`-`9`, and underscores.

In addition to this, Mab supports single spaces and dashes in identifiers with more
rules.
Note that it does not support _whitespace generally_, just single spaces,
and the spaces are part of the identifier.

The variables `delta x:number` and `deltax:number` are two different identifiers,
and this line of code is a syntax error, because it contains more than one space
between `delta` and `x`:
```
delta    x:number;
```

Dashes may only be placed between two other alphanumeric characters+underscores in a
variable name:
```
# Valid
dashed-identifier: 10;

# Valid, but maybe avoid this.
_-_: 10;

# Invalid:
-leading-dash-identifier: 10;

# Invalid:
trailing-dash-identifier-: 10;

# Invalid:
dash-and- space-identifier: 10;

# Invalid:
dash-and -space-identifier: 10;

# Valid:
Bree Over-the-Water: 10;
```
### Literals

#### Boolean
Boolean literals are `true` and `false`.

#### Numerals
Mab indicates a number of a specific base with the following format:

`0n<digits>`, where `n` is the last digit in the base. For example, `09 128` is the
number 128 in base 10, and `07 200` is 128 in base 8. `0F 80` is the same number in
hexidecimal.

All numbers may have single spaces between digits.

The default base in Mab is base 10, and in this base, no base prefix is necessary.

Numerals in base 10 without a base prefix may also have a fractional part and an
exponent:
```
112.10e10;
112.0
112.
.01e-3
```



### Function and Variable Definition

In Mab, variable definitions and function definitions share a unified syntax:
```
identifier ':' scope, type ['='] value
```

`value` is either an expression, or a block.

The equals sign is optional, and may be omitted. However, it can be more natural to
include after scope or type keywords to make it clearer that it's an assignment.
In certain cases, such as assigning to variables that start with scope or type
keywords, it can be included to disambiguate.

More or less natural:
```
# This is valid:
variable:global number 12;

# But this may be more readable:
variable2:global number = 12;
```

Disambiguation:
```
global style: false;

# This will fail, because it will be read as "failed style: global (style),"
# that is, a global variable named 'failed style' being assigned the value of
# another variable named 'style,' which doesn't exist.
failed style: global style;

# This will work, because the equals sign disambiguates.
successful style := global style;

```

Currently, function types may only be placed at the top level, outside of blocks,
in function definitions, and not within function parameter lists or in
function return types, as  Mab does not yet have first-class functions.

The `identifier` is the name of the variable or function. `scope` and `type` are
described in following sections.

### Scope

Scope is `global` or `local`. If no scope is specified, `local` is assumed.

`global` variables are accessible everywhere in the file after the function
where they are defined.

### Type 

Types can be either `boolean`, `number`, an array type, or a function type.

A function type is:
```
['('] {identifier ':' type {[,] identifier ':' type }} [')'] -> type
```

Currently, function types can only be top-level types, in function definitions,
as Mab does not yet support first-class functions.

An array type is:
```
'[' numeral ']' {'[' numeral ']'} type
```
The type in the array type can be a boolean or a number, but not a function or an
array.

Or alternatively and equivalently, but probably more confusingly,
you can consider the array type definition to be:
```
'[' numeral ']' type
```
Where type can be a boolean, number, or another array type.

The end result is something like this, where `[2][2] number` is an array type:

```
is identity: matrix:[2][2] number -> boolean {
  # Contents
}
```

### Example of Function and Variable Definitions

An example of some functions and variables in this syntax:
```
# This function has no input or return types.
# It can only be called with the `call` keyword, any other use would be a type checker error.
global container: -> {
    g:global = 12;
    @g;
}

factorial: (n:number) -> number {
    if n = 0 {
        return 1
    } else {
        return n * factorial(n - 1)
    }
}

sum: (a:number b:number) -> number = {
    return a + b
}

# The parethesis are optional, and commas can also be added if desired:
div: a:number, b:number -> number {
    return a / b
}

# This could also be written as " entry point: -> number ."
entry point: () -> number {
    call global container();

    # Fully specified variable
    a:local number = 2;
    # Equals is optional...
    b:= 2;
    # Other than the name, the same as the two previous.
    c: 2;

    return factorial( div( sum( a, b ) * c, 2) )
}
```

The result of executing the above example is `24.0`.

### Assignment

The grammar for assignments is:

```
identifier {'[' expression ']'} '=' expression
```

The middle part is the array index syntax. Note that each array index must evaluate 
to a number.

A couple of basic assignment examples:
```
a:number;

a = 3 * 6 + 4;

b: new[2][2] boolean;

b[1][1] = true;
```

### Unary and Binary Operators

Mab contains the following unary operators:

| Operator             | Operation | Type    |
|----------------------|-----------|---------|
| <center>`!`</center> | Not       | Boolean |
| <center>`+`</center> | Positive  | Numeric |
| <center>`-`</center> | Negate    | Numeric |

It contains the following numeric binary operators:

| Operator             | Operation      |
|----------------------|----------------|
| <center>`+`</center> | Addition       |
| <center>`-`</center> | Subtraction    |
| <center>`*`</center> | Multiplication |
| <center>`/`</center> | Division       |
| <center>`%`</center> | Modulus        |
| <center>`^`</center> | Exponent       |

And the following boolean binary operators:

| Operator              | Operation    |
|-----------------------|--------------|
| <center>`>=`</center> | Greater Than |
| <center>`>` </center> | Greater      |
| <center>`<=`</center> | Less Than    |
| <center>`<` </center> | Less         |
| <center>`~=`</center> | Not Equal    |
| <center>`=` </center> | Equal        |


### Ternary Operator

The ternary operator is an expression that evaluates to the value of one of its 
branches. Both branches must evaluate to the same type, and the conditional
expression before the `?` must evaluate to a boolean.

Here is its syntax:
```
expression '?' expression ':' expression
```

An example of usage:
```
a: 10;
b: 12;

c: a < b ? true : false;

```

### Operator Precedence

From lowest to highest:

| Operator                                     | Name                                  |
|----------------------------------------------|---------------------------------------|
| <center>`?:`</center>                        | Ternary                               |
| <center>`>=` `>` `<=` `<` `~=` `=` </center> | Boolean Comparisons                   |
| <center>`!` </center>                        | Boolean Not                           |
| <center>`+`  `-` </center>                   | Addition and Subtraction              |
| <center>`*` `/` `%` </center>                | Multiplication, Division, and Modulus |
| <center>`-` </center>                        | Unary Minus                           |
| <center>`^` </center>                        | Exponent                              |

### Statement Function Calls

A function whose return value is discarded after being called is a statement.

Mab requires a special keyword for this case, unlike most other languages:

```
'call' identifier '(' { expression { ',' expression } } ')'
```

Example of usage. Note that `print()` here has no return type, so it actually can only
be invoked with `call`:
```
print: (n:number) -> {
    @n
}

entry point: -> number {
    call print(10);
}
```

### Return

Syntax for returns is as follows:

```
'return' [':'] expression
```

A basic example:
```
a: 12;
b: 10;

return a * b;
```

One issue with return is that return can be confused with assignment in some cases.
The optional colon can be used to prevent this.
```
a: true;
b: false;

# This will be read as "(return a) = b;"
return a = b;

# You can correct this with the optional colon:
return: a = b;
```

### Arrays

Arrays in Mab are indexed from element one, not zero.

Mab is done this way because unifying the count and index of things is
more natural and less confusing.
It leads to intuitive properties such as the last element's index being the length of the array.

When creating an array, you use the `new` keyword:

```
'new' '[' numeral ']' {'[' numeral ']'} expression
```

The expression here is the default value of all the elements of the array.

```
a: new [2][2][3];
```

To access an element for use in expression or assignment:
```
identifier '[' expression ']' {'[' expression ']'}
```

### Control Structures
#### If / ElseIf / Else

These conditional control structures are typical. The syntax is as follows:

```
'if' expression '{' {statement} '}',
{'elseif' expression '{' {statement} '}'},
['else' '{' {statement} '}']
```
The expressions must evaluate to booleans.

An example of usage:
```
a: 12;
b: 10;

# Output the lesser of the two:
if a < b {
    @a;
} elseif a > b {
    @b;
# If equal, output the sum:
} else {
    @a + b;
}
```

#### While

The while loop is also typical. The syntax is as follows:

```
'while' expression '{' {statement} '}'
```

An example of usage:
```
a: 1;
b: 10;

# This will print the numbers 1 through 10 inclusive:
while a <= b {
    @a;
    a = a + 1;
}

```

### Print

The print statement is the character `@` followed by an expression:

```
entry point: -> number {
    n: 12;
    @n;
    
    a: new [2][2] true;
    a[1][1] = false;
    @a
}
```

The output from the example above is:
```
12
[
 [false, true],
 [true, true]
]
```

### Comments

Comments are denoted by `#` and continue to the end of the line.

Block comments are denoted by `#{` and `#}` and can span multiple lines.
Nesting block comments is not supported.

Example of usage:
```
# This is a comment

# And a block comment:
#{
    This is a block comment.
    It can span multiple lines.
    
    # This code will not be executed, because it is commented out in this block comment:
    a: 10;
    @a;
#}
```

## New Features/Changes

### Type Specification, Unified Types

As described in
**[Function and Variable Definition](#function-and-variable-definition).**
This differs significantly from Selene.

#### Limitations

This syntax was designed to support first-class and anonymous functions,
but they have not been implemented.

### Type Checker/Strongly Typed

Mab uses a type checker and is strongly typed.

Expressions are all recursively evaluated to types, and checked for compatibility
between operands and in parts of statements.

For example, this code will check if `true` is a boolean, because it must be to be the
condition of the ternary operator. It will then check to make sure both arms of the 
ternary match in type (which they don't!) and then return the type of the first arm in
order to continue checking, whether the check passed.

```
test: true ? 1 : false;
```

Variables are assigned types, or types are inferred from their assignments.
Further type inference is not performed.

Inferred to be a number:
```
var: 12;
```
Specified as a number, can be assigned a number later:
```
var:number;
var = 15;
```

This is not valid; variables must have a type or an initializer when first created:
```
var:;
var = true;
```

Conditionals only accept expressions that evaluate to booleans:

```
# Valid code
this is a boolean: true;
if this is a boolean {
    # The type checker is... pleased!
}

# Invalid code, will fail type check phase
this is a number: 12;
if this is a number {
    # Sadness and tears.
}
```

Boolean operators may only be used with boolean types:
```
number: 12;
another number: 15;

# This'll throw an error in the type checker.
a boolean: number & another number;
```

However, logical operators will cause a type conversion of the expression to a boolean, 
which will then be acceptable for conditionals or assignment to booleans:
``` 
a boolean = another number > number;
```

Arrays are also typed in both their number of dimensions and the size of each dimension.
```
# This is valid code.
array: = new[2][2] true;
subarray: = new[2] false;

# We can assign here because array[1] is a 2-element array of booleans, the same as subarray.
array[1] = subarray;

mismatched array: [3] true;

# This will fail in the type checker because the array sizes are different:
array[2] = mismatched array;

```

Array types can be specified, which is necessary for functions since the language is
strongly typed and has no support for anything like automatic generics:
```
is identity: matrix:[2][2] number -> boolean {
    i: 1;
    while i <= 2 {
        j: 1;
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
entry point: -> number {
    matrix:local [2][2] number:matrix = new[2][2] 0;
    # Same as :matrix = new[2][2] 0;
    
    matrix[1][1] = 1;
    matrix[2][2] = 1;
    return is identity(matrix)
}
```
Notably, array types are required to have initializers because default values are not
supported for them, making type specifiers even more useless.

#### Limitations

Further type inference would be nice. Rust is a great example of very robust automatic inference.

Types can be a bit clunky as it is right now.

Generics would also be a fun goal.

### Robust Error Support

Error messages indicate the line number, and show it along with surrounding context
lines with an indication of the exact character where the error occurs.

In addition, the output includes `filename:line number`, allowing some editors,
such as ZeroBrane Studio, to open the file when the error line is double-clicked in
the log.

#### Limitations
Some errors crash various phases, and even if they are caught, they can still be cryptic.

One approach to solve this would be to have a phase that does robust verification of the AST
for correctness to verify preconditions before further phase processing.

### Booleans

Basic boolean support. The default value of booleans is `false`.

There is intentionally no direct coercion between booleans and numbers,
i.e. `0` is not `false`, and conditionals may only accept booleans.

### Ternary Operator

The ternary operator has the same syntax as the C/C++ version:
`<expression> ? <evaluate if true> : <evaluate if false>`.

### Two-Pass Compilation

Rather than support forward declarations, Mab scans the entire AST up-front and
collects all functions before proceeding.

This is a slightly different approach to fulfilling the goals of the forward
declaration exercise, as it also allows for indirect recursion.

For example, this is valid Mab code:
```
entry point: -> number {
  n:global = 10;
  if even() = true {
    return 1
  } else {
    return 0
  }
}
even: -> boolean {
  if n ~= 0 {
    n = n - 1;
    return odd()
  } else {
    return true
  }
}
odd: -> boolean {
  if n ~= 0 {
    n = n - 1;
    return even()
  } else {
    return false
  }
}
```
#### Limitations

If I want to support modules, I'll need a new feature, as opposed to forward
declarations, which can be used for that with only slight modifications.

### More Name Collision Support

The exercises call for detecting collisions between global variables and functions, 
and parameters with the same name, and locals in the same scope sharing a name.

In addition to this, I prevent local variables with the same name as functions and
parameters with the same name as functions.

#### Limitations

If a local is given the same name as a global, the global will always be shadowed,
even if the global is created *after* the local, which is a bit odd.

For example, the following function will return 12, rather than generating a type
mismatch error:
```
entry point: () -> number {
  v:local = 12;
  v:global = false;

  return v
}
```

### Numeral Base Notation

As  described in **[Numerals](#numerals)**.

#### Limitations

This syntax can be a bit confusing to those used to other languages, because `0x80` in
Mab is 540 in base 10. 128 would be `0x5N` with this prefix, as it indicates base 35 in
Mab.

### Single Spaces in Numerals

Mab supports single spaces in numerals for digit grouping. For example, `1 000 000` is
valid as a way of writing the number one million.
This also works with base notation, and in fact the separator between the base prefix 
and the rest of the number is just part of this feature.

For example, one might write `0F FF FF 00` to group a 3-byte (24-bit) color,
or `01 1000 0110 1111` to write out a boolean mask in a readable way.

Digit grouping with spaces is supported by many standards organizations.
See, for example, the [22nd General Conference of Weights and Measures Resolution 10](https://www.bipm.org/en/committees/cg/cgpm/22-2003/resolution-10).

Commas and periods are culture-specific and can cause confusion between fractional
parts of the number and digit grouping.

### Single Spaces and Dashes in Identifiers

As described in **[Identifiers](#identifiers)**.

#### Limitations

There is some ambiguity with the `return` keyword and spaces, as it can be read as an
identifier in some cases, such as `return a = b`, which will be parsed as 
`return a` `=` `b` rather than `return` `a = b`. This particular case could also be
solved by requiring a different character than equals for assignment, by disallowing
the return keyword as a prefix for variables, or by using a double equals for equality.
The underlying issue is that every statement except for assignment and new variables
begins with a keyword, and every keyword-prefixed statement except for return has a
block opening after it.

The block opening is used to prevent confusion in all the other cases and allows for 
variables to begin with keywords followed by spaces, such as:
```
:if we win this time;
if we win this time = false;
if if we win this time {
    # Yes, this is pretty confusing, but the language is named after a
    # fairy of dreams and madness, right?
}
```

To avoid another case of ambiguity, a function call as a statement must be proceeded by
the `call` keyword. Because function calls like this can be a sign of mutating program
state in unclear ways, I judged that adding some friction to this case was not much of
a negative.

Dashes can also be confused with binary or unary operators. Requiring alphanumeric
characters on both sides avoids this issue in most cases, but I think there are some
programmers who would find the need for spaces all the time infuriating.

### Command-Line Options

Mab supports a robust array of command-line options:

* `--tests`: Run test suite. Must be first argument.
* `--input`/`-i`: Specify input file, relative to working directory.
* `--ast`/`-a`: Print the AST.
* `--code`/`-c`: Output the generated code.
* `--trace`/`-t`: Output an execution trace, with stack state after each instruction.
* `--result`/`-r`: Output the result of the program. (The return value from `entry point`.)
* `--echo-input`/`-e`: Output what was sent in to translate.
* `--graphviz`/`-g`: Generate a graphviz visualization and open it in Firefox. (Unstable.)
* `--pegdebug`/`-p`: Annotate the grammar with PegDebug before translating.
* `--type-checker-off`/`-y`: Disable the type checker phase. "Damn the torpedoes, full speed ahead!"
* `--stop-on-first-error`/`-s`: Stop outputting errors after the first.
* `--verbose`/`-v`: Output detailed information about stage execution.
* `--unpoetic`/`-u`: Suppress poetry.

You can use the format `-{option character}` to select multiple options at a time.
For example, `-vr` will output verbose information and the program return value.

### Automatic AST and Code Versioning

Changing the AST and code is likely to invalidate later phases of the translation
suite.

As Mab has a type checker and two different translators, sometimes the fact that a
particular phase hadn't been updated is lost in the shuffle.

Additionally, crashes and error messages caused by incompatible ASTs can be unclear.

To address these issues, Mab hashes the parser and seeds the hash of the Stack VM
translator with the parser hash. These versions are set for each phase, and if a 
phase's version is not updated after changes are made, a warning is output.
Additionally, if a phase crashes or has errors, the warning notes more strongly it may 
be due to the incompatibility.

The ideal workflow here is to update a phase, then verify each translator and update
its hash after it has been verified to be compatible with the updates.

## Future

### Make Mab Production-Ready

#### Extensive Documentation and Learning Resources
A pre-requisite for language adoption. There are many languages out there,
and expecting people to figure out a language through trial and error is
not only impractical, but disrespectful of their time.

#### Multiple File Support
This sort of strongly-typed language is well-suited to larger projects,
so supporting multiple files is a high priority.

#### Input/Output Support
Files, streams, program arguments, more robust printing, etc.
A programming language that you can't communicate with without changing source code
is clumsy at best.

#### Ahead-of-Time Compiled
Speed is important for me. I want a language that is performant enough to make games.

#### Safety Features
Safety is no longer optional. The world runs on software. Major business and
government organizations are advocating use of only memory-safe languages.

Even games can be attack vectors. Safety is needed for all software.

#### Foreign Function Interface
In order to work with all the hardware and software out there,
there needs to be some way to communicate with it.

Since Mab is designed to be an ahead-of-time compiled language,
standard ways of communicating with other languages would be vital.

#### More Control Structures
`while` is not enough. Needs more loops, iterators, etc.

#### More Data Types
Some way of representing and working with strings is vital.

Separating integer and floating point is useful for this type of language, as well.

#### Standard Library
Working with a language without a standard library can be impractically
time-consuming.

#### Consider Explicitly Supporting a Paradigm
Something like object-oriented programming, etc.

#### Multiprocessing Support
Even mobiles have many cores. This must be a first-class language feature,
especially for a performance-focused statically typed language like Mab.

### Mab Improvements and Extensions

These are some things I'd like to add or at least try to add,
but were outside the scope of my free time during the course.

#### Easy
* Constant support
* Entry Point case-insensitive?
* Include explicit version number and size for AST and code versions,
in addition to the hash.
* Disallow globals in default arguments, or remove default arguments.
* Do a pass over different keyword and symbol literals and consider
whether to make changes.
  * `~=`, `!`, comments. Others...
* Add options for unicode symbols for math instead of ASCII.
* Colon after conditionals instead of open block?
  * Just seems a little more natural to me...

#### Medium
* Make Language Loopier
  * `while`/`otherwise` loop.
    * If the loop condition fails immediately, the `otherwise` clause is executed.
  * Other types of loops, just `while` is a bit limiting.
  * `break` and `continue` for loops.
* `goto`.
* Offset-based array indexing syntax, for people who, when asked to count three apples,
would say "Zero, one, two. Three apples!"
  * Maybe `array+[0][0]`, `array+[1][1]` as equivalent to `array[1][1]` and `array[2][2]`?
* Language profiles with different rules.
  * Lua style, default `global`.
  * Shadowing on and off.
  * `const` by default or not.
  * Type checked or loose typed.
* Give error messages numbers and move them to a different file.
* Constant expression support, for things like array sizes.
* `recurse` keyword to indicate a function that calls itself.
* Make variables being undefined before usage an error.
  * Remove default values.
* Remove semicolons from the language.
* Use keywords for block delimiters rather than symbols.
  * A capture that looks at an entire line that starts with an identifier character
  in a location that an identifier is allowed could work for this.
* Support trailing base notation for numbers, rather than prefix.
  * `1000 b2`, for example.
* Report differences in AST based on hash of parser bytecode rather than text hash.
  * Text hash is sensitive to formatting, comments, and other irrelevant modifications.
  * `string.dump()` seems promising?

#### Hard
* First-class functions.
  * Mab's syntax was designed around doing this.
* Proper tail recursion.
  * With keyword, so it can be verified with an error that it's working.
* Much more robust type inference.
  * Be able to tell the type of variable based on first initialization.
  * Inferring function arguments based on their usage.
* Automatic generics.
* Multiple return values.
* Everything expressions.
  * Seems to conflict with other goals. Maybe have a construct that indicates
  a statement should produce a result?
  * This could replace `return`...
* Mix static and dynamic type checking.
  * See earlier idea of language profiles.
* Fix-ups for undefined globals and exports, or whatever concept is used for modules.
  * Two-pass compilation for all the things!
* Keywords for boolean operators or shared symbol operators.
  * The second one would involve doing something to assure sane precedence based on
  types.
  * The first would probably involve making the parser aware of valid variables.

## Self assessment

### Language Completeness: 3/3
* All exercises have been incorporated into the language, as well as two optional
features (booleans and the ternary operator) and the type checker.
* As reflected in **[New Features/Changes](#new-featureschanges)**, many changes have 
been made beyond basic project requirements.

### Code Quality & Report: 3/3

* Code organization is exceptional, with well-named files, organized into directories,
and phases numbered by order of execution.
* Error handling is user-friendly, with a wide variety of well-written error messages,
and in the worst case, exceptions in phase execution will be caught as internal errors.
* The language includes a suite of test cases.

### Originality & Scope: 3/3
* Mab has several experiments, including spaces in variable names, autogenerated AST
and code versions, and other unique syntax constructs such as parameter lists where
parentheses and commas are optional.
* Language is broken into different phases to allow localized changes, and is otherwise modular,
with things like literals defined in a single place for customization.

## References
Most of my research beyond asking questions on Discord was small Google searches,
but here are some relatively relevant links.

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
