# The Mab Programming Language

![An illustration of Queen Mab by Willy Pogany,
 a line drawing of a fairy in black and white with butterfly wings,
holding a rod and wearing a crown,
in a dress, her feet straight down,
and below her feet a single star.
 "Queen Mab" is written in the middle in script,
one word on either side of the figure.](Artwork/QueenMab.png#gh-light-mode-only "Queen Mab, Illustration by Willy Pogany")
![An illustration of Queen Mab by Willy Pogany,
a line drawing of a fairy in black and white with butterfly wings,
holding a rod and wearing a crown,
in a dress, her feet straight down,
and below her feet a single star.
"Queen Mab" is written in the middle in script,
one word on either side of the figure.](Artwork/QueenMabDark.png#gh-dark-mode-only "Queen Mab, Illustration by Willy Pogany")

## Instructions for Using Language, Input Program, and Test Suite

Requires Lua and LPeg available to Lua, tested with Lua 5.3 and 5.4.

To test the input program, clone the repository, and invoke it like this:

```
lua mab.lua input
```

To run your own code, replace `input` with the filepath.

To run the test suite:

```
lua mab.lua --tests
```

You can also invoke Mab like this if it's marked executable (which it should be on Linux):

```
./mab.lua input
```

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

Mab supports single spaces in numerals for digit grouping. For example, `1 000 000` is
valid as a way of writing the number one million.
This also works with base notation, and in fact the separator between the base prefix
and the rest of the number is just part of this feature.

For example, one might write `0F FF FF 00` to group a 3-byte (24-bit) color,
or `01 1000 0110 1111` to write out a boolean mask in a readable way.

The default base in Mab is base 10, and in this base, no base prefix is necessary.

Numerals in base 10 without a base prefix may also have a fractional part and an
exponent:
```
112.10e10;
112.0
112.
.01e-3
```
> *Background*
> 
> Digit grouping with spaces is supported by many standards organizations.
See, for example, the [22nd General Conference of Weights and Measures Resolution 10](https://www.bipm.org/en/committees/cg/cgpm/22-2003/resolution-10).
>
>Commas and periods are culture-specific and can cause confusion between fractional
parts of the number and digit grouping.


#### Strings

Strings are delimited by single quotes. To insert a single quote in a string, use two single quotes.

Strings may span multiple lines.

If the first line in a string is a newline followed by some whitespace,
said whitespace will be stripped from the start of all lines,
and the beginning newline will be removed.

For example:

```
entry point: -> number {
  a string: '# Let''s have fun!';

  an embedded program:
    '
    # Our favorite recursive program
    entry point: -> number {
      return factorial(10)
    };
    
    factorial: (n:number) -> number {
      if n = 0 {
        return 1;
      };
      return n * factorial(n - 1);
    }
    ';

  @a string;
  @an embedded program;
}
```

Will output:

```
# Let's have fun!
# Our favorite recursive program
entry point: -> number {
  return factorial(10)
};

factorial: (n:number) -> number {
  if n = 0 {
    return 1;
  };
  return n * factorial(n - 1);
};

```

### Function and Variable Definition

In Mab, as functions are first-class, variable definitions and function definitions are fundamentally identical:
```
identifier ':' [scope] [type] [['='] value]
```

`value` is either an expression, or a block.

The equals sign is optional, and may be omitted. However, it can be more natural to
include after scope or type keywords to make it clearer that it's an assignment.
In certain cases, such as assigning to variables that start with scope or type
keywords, it can be included to disambiguate.

Variables with types specified do not need assignments, other than array types, which are required to have them.\
This is a consequence of not supporting default values for array types.

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

# This will fail, because it will be
# read as:
#  "failed style: global (style),"
# that is, a global variable named 
# 'failed style' being assigned the
# value of  another variable named
# 'style,' which doesn't exist.
failed style: global style;

# This will work, because the equals
# sign disambiguates.
successful style := global style;
```

The `identifier` is the name of the variable or function. `scope` and `type` are
described in following sections.

### Top-Level

A Mab program is a series of new variable statements separated by semicolons.

All variables at the top level are global by default, and particularly functions must be global.
It's currently an error to specify a top-level function as anything else.

Unfortunately, this means that yes, you do need semicolons after function blocks:

```
factorial: (n:number) -> number {
    if n = 0 {
        return 1
    } else {
        return n * factorial(n - 1)
    }
}; # < Don't forget this semicolon!

entry point: () -> number {
    return factorial(5)
} # < The final definition's semicolon is optional.
```

#### The Entry Point

Mab programs must contain a function named `entry point` that takes no arguments and
returns a number.\
This entry point will be executed when the program starts.

### Scope

Scope is `global` or `local`. If no scope is specified,
`global` is assumed at top-level and `local` otherwise.

`global` variables are accessible everywhere in the file after the location they are defined.

### Type 

Types can be either `boolean`, `number`, an array type, or a function type.

A function type is:
```
['(' {identifier ':' type {[,] identifier ':' type }} ')'] -> [type]
```
As indicated above, type of none for the input is also allowed:
```
 -> number
```

Or empty:
```
() ->
```
And the output type can also be none:
```
->
```

An array type is:
```
'[' numeral ']' {'[' numeral ']'} type
```
The type in the array type can be a boolean, a number, or a function type.

Or alternatively and equivalently, but probably more confusingly,
you can consider the array type definition to be:
```
'[' numeral ']' type
```
Where type can be a boolean, a number, a function type, or another array type.

The end result is something like this, where `[2][2] number` is an array type:

```
is identity: (matrix:[2][2] number) -> boolean {
  # Contents
}
```

### Example of Function and Variable Definitions

An example of some functions and variables in this syntax:
```
# This function has no input or
# return types.
# It can only be called with the
# `call` keyword, any other use
# would be a type checker error.
global container: -> {
    g:global = 12;
    @g;
};

factorial: (n:number) -> number {
    if n = 0 {
        return 1
    } else {
        return n * factorial(n - 1)
    }
};

sum: (a:number b:number) -> number = {
    return a + b
};

# Commas can also be added if
# desired:
div: (a:number, b:number) -> number {
    return a / b
};

# This could also be written as
#   entry point: -> number
entry point: () -> number {
    call global container();

    # Fully specified variable
    a:local number = 2;
    # Scope and type are optional...
    b:= 2;
    # Equals also optional...
    # Other than the name, the same
    # as the two previous.
    c: 2;

    return factorial( div( sum( a, b ) * c, 2 ) )
}
```

The result of executing the above example is `24.0`.

### Assignment

The grammar for assignments is:

```
identifier {'[' expression ']'} '=' expression
```

The middle part is the array index syntax. Note that each array index must evaluate 
to a number. (But it is not necessary for them to be *literal* numbers,
again, just a thing that *evaluates* to a number.)

A couple of basic assignment examples:
```
a:number;

a = 3 * 6 + 4;

b: new[2][2] boolean;

b[1][1] = true;
```

### Unary and Binary Operators

In Mab, using an operator with a mismatched type is an error.\
Particularly, using a boolean operator with a number is an error.

If you're familiar with C or C++, you might tend to do this:
```
a:number = 0;

# Operations on a...

if a {
    # ...
};
```
But that's an error.

This is probably what you want:
```
if a ~= 0 {
    # ...
};
```

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

The following boolean binary operators:

| Operator              | Operation    |
|-----------------------|--------------|
| <center>`>=`</center> | Greater Than |
| <center>`>` </center> | Greater      |
| <center>`<=`</center> | Less Than    |
| <center>`<` </center> | Less         |
| <center>`~=`</center> | Not Equal    |
| <center>`=` </center> | Equal        |

And the following boolean logical operators:

| Operator               | Operation |
|------------------------|-----------|
| <center>`&`</center>   | And       |
| <center>`\|` </center> | Or        |

> *Note*
> 
> The logical operators short-circuit. For `&`, this means that if the left side is `false`,
the right side is not evaluated. This includes potential side effects like function calls.
> For `|`, if the left side is `true`, the right side is not evaluated.

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
| <center>`&` `\|`</center>                    | Boolean Logical                       |
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
'call' identifier '(' [ expression { ',' expression } ] ')'
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

# This will be read as:
#   (return a) = b;
# (Note that the parentheses above
   are for clarification,
   they aren't supported.)
return a = b;

# You can correct this with the optional colon:
return: a = b;
```

### Arrays

Arrays in Mab are indexed from element one, not zero.

Mab is done this way because unifying the count and index of things is
more natural and less confusing.
It leads to intuitive properties such as the last element's index being the length of the array.

However, if you want to index arrays by offset, use this notation, with a `+` before the first `[`:

```
# This sets the first element of a to 12:
a+[0] = 12;
```

When creating an array, you use the `new` keyword:

```
'new' '[' numeral ']' {'[' numeral ']'} expression
```

The expression here is the default value of all the elements of the array.

```
a: new [2][2][3];
```

> *Note*
>
> Because array types are statically typed in size, only literal numbers
> may be used to initialize their sizes with `new`.
>
> A future Mab goal is to support something like constant variables and expressions here.
>
> The grammar can accept expressions, and the expressions could be coded—and were in earlier versions of Mab—but
> the type checker will reject array sizes that are not literals at the moment.



To access an element for use in expression or assignment:
```
identifier '[' expression ']' {'[' expression ']'}
```

### Control Structures
#### If / ElseIf / Else

These conditional control structures are typical. The syntax is as follows:

```
'if' expression '{' {statement list} '}',
{'elseif' expression '{' {statement list} '}'},
['else' '{' {statement list} '}']
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
'while' expression '{' {statement list} '}'
```

An example of usage:
```
a: 1;
b: 10;

# This will print the numbers
# 1 through 10 inclusive:
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
};
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

    # This code will not be executed
    # because it is commented out in
    # this block comment:
    a: 10;
    @a;
#}
```

## Other Notes on Features

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
    # The type checker is...
    #   pleased!
};

# Fails the type check:
this is a number: 12;
if this is a number {
    # Sadness and tears.
};
```

Boolean operators may only be used with boolean types:
```
number: 12;
another one: 15;

# Fails type check!
#   Can't use & with numbers.
a boolean: number & another one;
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

# We can assign here because
# array[1] is a 2-element array of
# booleans, the same as subarray.
array[1] = subarray;

mismatched array: [3] true;

# This will fail in the type checker
# because the array sizes are
# different:
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
      };
      elseif i ~= j & matrix[i][j] ~= 0 {
        return false;
      };
    };
  };
  return true;
}
```

But currently redundant and useless for variables:
```
entry point: -> number {
    matrix:[2][2] number = new[2][2] 0;
    # Same as matrix: new[2][2] 0;

    matrix[1][1] = 1;
    matrix[2][2] = 1;
    return is identity(matrix);
};
```
Notably, array types are required to have initializers because default values are not
supported for them, making type specifiers even more useless.

#### Limitations

Further type inference would be nice. Rust is a great example of very robust automatic inference.

Types can be a bit clunky as it is right now.

Generics would also be a fun goal.

### Two-Pass Compilation

Rather than support forward declarations, Mab scans the entire AST up-front and
collects all top-level functions before proceeding, and sets them as global.

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

You can also send in a filename directly and Mab will execute it, as long as it doesn't start with a dash.
If it *does*, use the `-i` option.

Example:
```
./mab.lua program.mab
```
Verbose settings:
```
./mab.lua --verbose program.mab
```

Explicit filename:
```
./mab.lua -i program.mab
```

Short options:
```
./mab.lua -vr program.mab
```

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

#### Debugging Tools
Good debuggers reduce development time and increase software quality.

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

Separating integer and floating point is useful.

Sized types are also important for many use cases.

Finally, some sort of compound type, such as tuples with named elements.

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

#### Chores
* Re-do test organization, with directory and specific files.
* More robust information about what went wrong when test goes awry.
  * Perhaps report errors?
* Error changes.
  * Error codes.
  * Errors in a separate file.
* When hashing and versioning, include an explicit version number and size of the files.

#### Easy
* Error themes. (After *Error changes* above.)
* Localization support (see *Error changes* above.)
* Constant support
  * Maybe limit default `const` to function parameters?\
  See also the *Language profiles* idea.
* String improvements.
  * Support for escape sequences.
* Disallow globals in default arguments, or remove default arguments.
* Do a pass over different keyword and symbol literals and consider
whether to make changes.
  * `~=`, `!`, comments. Others...
* Add options for unicode symbols for math and types instead of ASCII.
* Colon after conditionals instead of open block?
  * Just seems a little more natural to me...
* Disallow names composed entirely of keywords.
* A different way to specify array default values, such as a `default` keyword?\
  Maybe `array [2] default(0)`?
* Error phase before type checking.

#### Medium
* Make Language Loopier
  * `break` and `continue` for loops.
  * Other types of loops, just `while` is a bit limiting.
    * `for value in array`, `for index, value in array`.

      Maybe `:` instead of `in`?

      No need to support looping over indices by themselves.
  * `while`/`otherwise` loop.
    * If the loop condition fails immediately, the `otherwise` clause is executed.
* `goto`.
* Way of returning nothing, for functions that have no return type.
  * `exit` statement?
* Ability to get size of array, since it's static.
* Language profiles with different rules.
  * Lua style, default `global`.
  * Shadowing on and off.
  * `const` by default or not.
  * Type checked or loose typed.
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
  * Allow identifiers to start with numbers, as long as they contain at least one letter or underscore,
  and don't contain a trailing `b<n>`.
* Enumerations.
* For version hashing, strip irrelevant information like comments and whitespace out of the file first.
  * Considered using hash of Lua bytecode, but it's not portable and not stable across versions.
* Type aliases: numeral:type number; true or false:type boolean.
  * Interesting problem, if I do this, maybe function parameter lists will need to have commas.
* Anonymous functions (Lambdas).
* Backtrack comments and whitespace on error, not just whitespace.

#### Hard
* Proper tail recursion.
  * With keyword, so it can be verified with an error that it's working.
* Closures.
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
* Report source line on interpreter errors.
* Full debugger support.
* Bitwise operators with the same operator as booleans.

## References
Some links relevant to languages and development of the Mab language.

### [syntax across languages](http://rigaux.org/language-study/syntax-across-languages.html)
I used this to get some ideas for function syntax.

### [Frink](https://frinklang.org/)
A programming language that does unit checking.

### [Strings in C#](https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/strings/)
Some of C#'s string features inspired me, particularly the removal of leading whitespace based on final line indentation.
(I used the first line, instead.)

### [OCaml Book: Recursive Functions](https://ocamlbook.org/recursive-functions/#recursive-binding-syntax)
Hugo mentioned OCaml's keywords for recursion, I was curious and looked it up here.

### [GLSL Programming/Vector and Matrix Operations](https://en.m.wikibooks.org/wiki/GLSL_Programming/Vector_and_Matrix_Operations)
This is an example of a language heavily tilted toward vector math.

### [Pattern Matching for InstanceOf](https://bugs.openjdk.org/browse/JDK-8250623)
An interesting bug with a discussion related to type inference.

### [JavaScript: How Line Breaks and Missing Semicolons Can Break Your Code](https://javascript.plainenglish.io/javascript-how-line-breaks-and-missing-semicolons-can-break-your-code-58e031e7f235)
The woes of automatic semicolon insertion in JavaScript.

### [Lambda Lifting](https://en.wikipedia.org/wiki/Lambda_lifting)
Hugo mentioned this, and I read it while trying to figure out how to support first-class functions,
though I ended up going with the solution of making them globals at the top level.

### [Crafting Interpreters: Closures](https://craftinginterpreters.com/functions.html#local-functions-and-closures)
I read this while trying to figure out first-class functions.
I will come back to it if I want to support closures later!
