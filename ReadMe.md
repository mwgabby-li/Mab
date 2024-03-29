# The Mab Programming Language

![An illustration of Queen Mab by Willy Pogany,
a line drawing of a fairy in black and white with butterfly wings,
holding a rod and wearing a crown,
in a dress, her feet straight down,
and below her feet a single star.
"Queen Mab" is written in the middle in script,
one word on either side of the figure.](Artwork/QueenMabDark.png#gh-dark-mode-only "Queen Mab, Illustration by Willy Pogany")
![An illustration of Queen Mab by Willy Pogany,
 a line drawing of a fairy in black and white with butterfly wings,
holding a rod and wearing a crown,
in a dress, her feet straight down,
and below her feet a single star.
 "Queen Mab" is written in the middle in script,
one word on either side of the figure.](Artwork/QueenMab.png#gh-light-mode-only "Queen Mab, Illustration by Willy Pogany")
<p style="text-align: center;"><i>Image from</i> A Treasury of Verse for Little Children, <i>illustrated by William Andrew Pogany, stories selected by
M. G. Edgar</i>.</p>

## On Names

One of the things Mab is named after is [a moon, Uranus XXVI](https://solarsystem.nasa.gov/moons/uranus-moons/mab/in-depth/).
A moon reference was chosen as a nod to the Lua programming language, and to Roberto Ierusalimschy.

Mab's translation suite and interpreter is written in [Lua](https://www.lua.org/) and uses [LPeg](https://www.inf.puc-rio.br/~roberto/lpeg/),
and the class where Mab was constructed was led by Roberto.

Uranus XXVI and Mab are both also named after the fairy queen that is referenced in Shakespeare's _Romeo and Juliet_.

Other reasons for the name:
* Not used by any other technology as far as I could tell. 
* Diminutive character: The language is a tiny toy for a class, and Mab is tiny in the story. 
* A thing of dreams and fantasies: It is an experiment in some of the PL fantasies I've dreamt of. 
* Tricks, fate, and the dark side of dreams: I'm not expecting everything to work out.
  * The fact that it's only a mirrored letter away from "Mad" is another thing
  beyond the story that plays into this.

The [original poem (known as _Mercutio's speech_) can be found on Wikipedia](https://en.wikipedia.org/wiki/Queen_Mab#Mercutio's_speech).

An extremely shortened form of the poem, which was composed for the Mab programming language, is below:

> _In dreams, Queen Mab arrives unseen,_\
 _A dainty fairy, slight and lean._\
_Upon a carven hazelnut,_\
_With insect steeds, reigns finely cut._
>
> _Through slumber's realm, she softly flies,_\
_Bestowing dreams before our eyes._\
_To lovers' hearts, brings sweet amour,_\
_To soldiers, scenes of battles' roar._
>
> _Beware her touch, enchanting still,_\
_For fickle fate may bend at will._\
_In dreams, delight may find its cost,_\
_As morning breaks, and all is lost._

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

In Mab, the set of characters used in identifiers is
`A`-`Z`, `a`-`z`, the digits `0`-`9`, underscores, dashes, and single spaces.

Identifiers that refer to functions may not start with any conditional keywords, such as `'if'` and `'while'`.\
This removes some ambiguity, so `if a {}` is always read as `if (a) {}` and `while true {}` is always read as `while (true) {}`.

They may start with digits, but must contain at least one letter,
and may not end with the following suffix, as it indicates a number in base notation:

```
' b' digit {[' '] digit}
```

Note the space before `b`. E.g. `aab12` is a valid identifier, but `aa b12` is not.

As far as spaces in identifiers, note that Mab does not support _whitespace generally_, just single spaces,
and the spaces are part of the identifier.

The variables `delta x:number` and `deltax:number` are two different identifiers,
and this line of code is a syntax error, because it contains more than one space
between `delta` and `x`:
```
delta    x:number
```

Dashes also have some additional rules. They may only be placed between two other alphanumeric characters+underscores in a
variable name:
```
-- Valid
dashed-identifier: 10

-- Valid, but maybe avoid this.
_-_: 10

-- Valid:
1st: 1

-- Valid:
Blob10: true

-- Invalid, ending in ' b<digits>`
-- is not allowed.
Blo b10: true

-- Valid. It's a boolean (not a function type).
if test: true

-- Not valid, it's a function type.
if function: -> {}

-- This is OK, since there's no space.
ifFunction: -> ()

-- Invalid:
-leading-dash-identifier: 10

-- Invalid:
trailing-dash-identifier-: 10

-- Invalid:
dash-and- space-identifier: 10

-- Invalid:
dash-and -space-identifier: 10

-- Valid:
Bree Over-the-Water: 10
```

> *Notes*
> 
> The dash exclusions are to prevent confusion between the negative operators and dashed identifiers.

### Literals

#### Boolean
Boolean literals are `'true'` and `'false'`.

#### Numerals

##### Base 10
For base 10 numerals, Mab is typical, other than allowing single spaces between digits:

```
digit {[' '] digit}
```

The single spaces are supported for digit grouping. For example, `1 000 000` is
valid as a way of writing the number one million.

Numerals in base 10 without a base prefix may also have a fractional part, denoted by:
```
'.' [digit {[' '] digit}]
```
They may also have an exponent, denoted by:
```
'b^' ['+' | '-'] digit {[' '] digit}
```
Note that `b^` must be included, not just `b`. `b^` is meant to suggest 'number's base to power.'

Some examples:
```
112.       -- 112
112.0      -- 112
112b^7     -- 1 120 000 000
112.1 b^+7 -- 1 121 000 000
112.1b^-3  -- 0.1121
```

##### Bases 1-36

Mab indicates a numeral of a specific base with the following format, up to base 37:

```
digitOrLetter {[' '] digitOrLetter} ' b' digit {digit}
```

Base 36 is the limit because that's the maximum numeral that can be represented with digits
composed of `0-9`, `a-z`, starting from `a` as 10 to `z` as 35.

The trailing `' b' digit {digit}` is the base. For example, `128 b10` is the
number 128 in base 10, and `200 b8` is 128 in base 8. `80 b16` is the same number in
hexidecimal.

Note that a single space between the number and the base indicator is required.

As noted earlier, `b` is meant to suggest the word 'base.'

In base 36—the maximum supported—128 would be `3k b36`.

Digit grouping with spaces is also supported for numbers written in arbitrary base notation.

For example, one might write `FF FF 00 b16` to group a 3-byte (24-bit) color,
or `1000 0110 1111 b2` to write out a boolean mask in a readable way.

> *Background*
> 
> Digit grouping with spaces is supported by many standards organizations.
See, for example, the [22nd General Conference of Weights and Measures Resolution 10](https://www.bipm.org/en/committees/cg/cgpm/22-2003/resolution-10).
>
>Commas and periods are culture-specific and can cause confusion between fractional
parts of the number and digit grouping.


#### Strings

##### Double-Quoted (With Single Quotes)
The preferred Mab string notation is to start a string with two single quotes.

These strings will continue until two single quotes not followed by an
escape character or another single quote. This includes line breaks:
```
''This string's terminated in two single quotes.
You can include "double quotes" and 'single quotes'
in this string without needing to escape them.''
```

This format should almost never need escapes, as two single quotes next to each other are rare.

##### Double-Quoted
A string starting with double quotes continues until a double quote not followed by an escape character or
another double quote:
```
"This string's terminated in a double quote."
```

##### Special Character Delimited
If you start a string with a single quote and a non-alphanumeric, non-whitespace character, it will continue until
that character not followed by escape characters or repetitions of that character itself:

```
'@Put all the characters you like, no escapes needed except for @s: '"\/!#$%^&*().@
```

Because `delimiter 's'` is an escape sequence meaning 'the delimiter itself,' this string is valid. It becomes:
```
Put all the characters you like, no escapes needed except for @: '"\/!#$%^&*().
```

##### Repeated Special Character Delimited
A string starting with a single quote, then a number n, then a special character, will end when n repetitions of 
the special character are not followed by an escape sequence or that special character.
```
'3@You don't even need to escape single @s in this string. Only @@@s needs to be escaped.@@@'
```
In this string, `@s` is not an escape sequence, because `@` is not the delimiter, `@@@` is. It becomes:
```
You don't even need to escape single @s in this string. Only @@@ needs to be escaped.
```

##### Format Analogies
Two single quotes is analogous to writing a string in the repeated delimited format like so:
```
'2'This is a string ending in two single quotes.''
```

Starting with a double quote is like writing a string in the special character delimited form like so:
```
'"This is a string that is terminated by a double quote."
```

Or the repeated special character format, like so:
```
'1"This is a string that is terminated by a double quote."
```

Which is the same for any special character; omitting the number is as if a `1` had been specified:
```
'1@This is a string that is terminated by an @s.@
```

##### Closing Quote

Because it's easy to forgot that you don't have to balance the closing quote,
special character delimited strings will ignore trailing single quotes:

```
'1@This is a string that is terminated by an @s.@'
```

This doesn't apply to string delimited by single quotes already, as the ending characters will always be all consumed,
and even included as noted in the [section covering this](#ending-character-quirk).

##### Ending Character Quirk

As noted, the string will end at the first delimiter that isn't followed by an escape sequence or the delimiter itself.
This means that if you have multiple delimiters at the end of the string, they will all be included except for the
*n* last ones, where *n* is the multiplicity of the delimiter.

This means that you don't ever need to escape single quotes with the repeated single quote
format, even if they're at the end:

```
'''This string is surrounded by single quotes.'''
```
This results in:
```
'This string is surrounded by single quotes.'
```

The same is true of other delimiters:

```
'3@This string ends in three @s @@@@@@
```
This results in:
```
This string ends in three @s @@@
```
This string also produces the above result, without using the quirk:
```
'3@This string ends in three @s @@@s@@@
```

Finally, this quirk actually holds for any number of delimiters before an escape sequence.

##### Escape Characters

Include these escape characters after the specified delimiter in strings to produce the following results:

| Character                    | Meaning                                                               |
|------------------------------|-----------------------------------------------------------------------|
| `a`                          | Bell                                                                  |
| `b`                          | Backspace                                                             |
| `f`                          | Form Feed                                                             |
| `n`                          | New line                                                              |
| `r`                          | Carriage Return                                                       |
| `t`                          | Horizontal Tab                                                        |
| `v`                          | Vertical Tab                                                          |
| `1`-`9`                      | Repeats of Delimiter Character<br/>(Not repeated delimiter sequence.) |
| `0`                          | Null<br/>(Technically \0 is null in 'base 8')                         |
| `'0'{octal digit}`           | Literal Value in Base 8                                               |
| `'x'\|'X'{hex digit}`        | Literal Value in Base 16                                              |

##### Multi-line Strings and Whitespace Stripping

Any of the above string formats can be used for multi-line strings, and additionally, they all support the leading
whitespace stripping feature.

If the first line in a string is a newline followed by some whitespace,
said whitespace will be stripped from the start of all lines,
and the beginning newline will be removed.

For example:

```
entry point: -> number {
  a string: ''-- Let's have "fun!"''

  an embedded program:
    ''
    -- Our favorite recursive program
    entry point: -> number {
      factorial(10) -> result
    }
    
    factorial: (n:number) -> number {
      if n = 0 {
        1 -> result
      }
      n * factorial(n - 1) -> result
    }
    ''

  @a string
  @an embedded program
}
```

Will output:

```
-- Let's have "fun!"
-- Our favorite recursive program
entry point: -> number {
  factorial(10) -> result
}

factorial: (n:number) -> number {
  if n = 0 {
    1 -> result
  }
  n * factorial(n - 1) -> result
}

```

To align the first line with whitespace, include an empty line of whitespace after the first newline, like so,
where 's' is a space:

```
   @''
ssssss
sssssssssssText Starting Here
ssssssLine 1
ssssssLine 2''
```

This will result in this output. Everything up to and including the second end-of-line will not be included in the
final string:

```
     Text Starting Here
Line 1
Line 2
```

### Function and Variable Definition

In Mab, as functions are first-class, variable definitions and function definitions are fundamentally identical:
```
identifier ':' [scope] ([type] ['='] value | 'default' type)
```

`value` is either an expression, or a block.

If no value is specified, then the `default` keyword must be used, followed by a type:
```
x: default number

y: default boolean
```

The equals sign is optional, and may be omitted. However, it can be more natural to
include after scope or type keywords to make it clearer that it's an assignment.
In certain cases, such as assigning to variables that start with scope or type
keywords, it can be included to disambiguate.

Variables with types specified do not need assignments, other than array and function types.\
This is a consequence of not supporting default values for these types.

More or less natural:
```
-- This is valid:
variable:global number 12

-- But this may be more readable:
variable2:global number = 12
```

Disambiguation:
```
global style: false

--/ Failure Case
This will fail, because it will be
read as:
 "failed style: global (style),"
 that is, a global variable named
 'failed style' being assigned the
 value of  another variable named
 'style,' which doesn't exist.
--\
failed style: global style

-- This will work, because the equals
-- sign disambiguates.
successful style := global style
```

The `identifier` is the name of the variable or function. `scope` and `type` are
described in following sections.

### Top-Level

A Mab program is a series of new variable statements.

All variables at the top level are global by default, and particularly functions must be global.
It's currently an error to specify a top-level function as anything else.

```
factorial: (n:number) -> number {
    if n = 0 {
        1 -> result
    } else {
        n * factorial(n - 1) -> result
    }
}

entry point: () -> number {
    factorial(5) -> result
}
```

#### The Entry Point

Mab programs must contain a function named `entry point` that takes no arguments and
results in a number.\
This entry point will be executed when the program starts.

### Scope

Scope is `global` or `local`. If no scope is specified,
`global` is assumed at top-level and `local` otherwise.

`global` variables are accessible everywhere in the file after the location they are defined,
except for functions at the top level, which are available before and after their definitions.

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
  -- Contents
}
```

The last function parameter may have a default argument specified, as an expression.
This may be removed from the language in the future.

Example:

```
default arguments: (n:number = 12 * 17) -> number {
  n -> result
}

entry point: -> number {
  default arguments() -> result
}
```

### Example of Function and Variable Definitions

An example of some functions and variables in this syntax:
```
-- This function has no input or
-- result types.
global container: -> {
    g:global = 12
    @g
}

factorial: (n:number) -> number {
    if n = 0 {
        1 -> result
    } else {
        n * factorial(n - 1) -> result
    }
}

sum: (a:number b:number) -> number = {
    a + b -> result
}

-- Commas can also be added if
-- desired:
div: (a:number, b:number) -> number {
    a / b -> result
}

-- This could also be written as
--   entry point: -> number
entry point: () -> number {
    global container()

    -- Fully specified variable
    a:local number = 2
    -- Scope and type are optional...
    b:= 2
    -- Equals also optional...
    -- Other than the name, the same
    -- as the two previous.
    c: 2

    factorial( div( sum( a, b ) * c, 2 ) ) -> result
}
```

The result of executing the above example is `24.0`.

### Assignment

The grammar for assignments is:

```
expression -> identifier {'[' expression ']'}
```

The part at the end is the array index syntax.
Note that each array index must evaluate  to a number.
(But it is not necessary for them to be *literal* numbers,
again, just a thing that *evaluates* to a number.)

A couple of basic assignment examples:
```
a:default number

3 * 6 + 4 -> a

b: new[2][2] boolean

true -> b[1][1]
```

### Unary and Binary Operators

In Mab, using an operator with a mismatched type is an error.\
Particularly, using a boolean operator with a number is an error.

If you're familiar with C or C++, you might tend to do this:
```
a:number = 0

-- Operations on a...

if a {
    -- ...
}
```
But that's an error.

This is probably what you want:
```
if a ~= 0 {
    -- ...
}
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
a: 10
b: 12

c: a < b ? true : false
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

### Function Results

Syntax for results is as follows:

```
expression -> 'result'
```

A basic example:
```
a: 12
b: 10

a * b -> result
```

If the function has no result, `exit` can be used to exit early.\
It may also be optionally placed at the end:
```
no result: -> {
    @'I don't do anything. Wait, I print this string!'

    exit
}
```

### Arrays

Arrays in Mab are indexed from element one, not zero.

Mab is done this way because unifying the count and index of things is
more natural and less confusing.
It leads to intuitive properties such as the last element's index being the length of the array.

To index an array, use this notation:

```
array identifier ['+']'[' expression ']'{ '[' expression ']' }
```

The optional `+` before the first `[]` is array offset notation, aka zero-indexing:

```
-- This sets the first element of 'a'
-- to 12:
12 -> a+[0]

-- A single '+' will make all indices
-- in the list offset-indexed:
10 -> b+[0][1]
```

When creating an array, you use the `new` keyword:

```
'new' '[' numeral ']' {'[' numeral ']'} expression
```

The expression here is the default value of all the elements of the array.

```
a: new [2][2][3]
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
a: 12
b: 10

-- Output the lesser of the two:
if a < b {
    @a
} elseif a > b {
    @b
-- If equal, output the sum:
} else {
    @a + b
}
```

#### While

The while loop is also typical. The syntax is as follows:

```
'while' expression '{' {statement list} '}'
```

An example of usage:
```
a: 1
b: 10

-- This will print the numbers
-- 1 through 10 inclusive:
while a <= b {
    @a
    a + 1 -> a
}
```

### Print

The print statement is the character `@` followed by an expression:

```
entry point: -> number {
    n: 12
    @n
    
    a: new [2][2] true
    false -> a[1][1]
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

Comments are denoted by `--` and continue to the end of the line.

Block comments are denoted by `--/` and `--\ ` and can span multiple lines.
Nesting block comments is not supported.

Anything in between the `--/` and `--\ ` will be ignored.

Example of usage:
```
-- This is a comment

-- And a block comment:
--/ Title of Block Comment

    This is a block comment.
    It can span multiple lines.

    -- This code will not be executed
    -- because it is commented out in
    -- this block comment:
    a: 10
    @a
--\ b: 10 -- < This code is outside
```

## Other Notes on Features

### Type Checker/Strongly Typed

Mab uses a type checker and is strongly typed.

Expressions are all recursively evaluated to types, and checked for compatibility
between operands and in parts of statements.

For example, this code will check if `true` is a boolean, because it must be to be the
condition of the ternary operator. It will then check to make sure both arms of the 
ternary match in type (which they don't!). The result will be assumed to be type of the
first arm in order to continue checking, whether the check passed.

```
test: true ? 1 : false
```

Variables are assigned types, or types are inferred from their assignments.
Further type inference is not performed.

Inferred to be a number:
```
var: 12
```
Specified as a number, can be assigned a number later.
Note the `default` keyword is required for variables without assignments:
```
var:default number
15 -> var
```

This is not valid; variables must have a type or an initializer when first created:
```
var:
true -> var
```

Conditionals only accept expressions that evaluate to booleans:

```
-- Valid code
this is a boolean: true
if this is a boolean {
    -- The type checker is...
    --   pleased!
}

- Fails the type check:
this is a number: 12
if this is a number {
    - Sadness and tears.
}
```

Boolean operators may only be used with boolean types:
```
number: 12
another one: 15

-- Fails type check!
--   Can't use & with numbers.
a boolean: number & another one
```

However, logical operators will cause a type conversion of the expression to a boolean, 
which will then be acceptable for conditionals or assignment to booleans:
``` 
another number > number -> a boolean
```

Arrays are also typed in both their number of dimensions and the size of each dimension.
```
-- This is valid code.
array: = new[2][2] true
subarray: = new[2] false

-- We can assign here because
-- array[1] is a 2-element array of
-- booleans, the same as subarray.
subarray -> array[1]

mismatched array: [3] true

-- This will fail in the type checker
-- because the array sizes are
-- different:
mismatched array -> array[2]
```

Array types can be specified, which is necessary for functions since the language is
strongly typed and has no support for anything like automatic generics:
```
is identity: matrix:[2][2] number -> boolean {
  i: 1
  while i <= 2 {
    j: 1
    while j <= 2 {
      if (i = j & matrix[i][j] ~= 1) |
         (i ~= j & matrix[i][j] ~= 0) {
        false -> result
      }
    }
  }
  true -> result
}
```

But currently redundant and useless for variables:
```
entry point: -> number {
    matrix:[2][2] number = new[2][2] 0
    -- Same as matrix: new[2][2] 0

    1 -> matrix[1][1]
    1 -> matrix[2][2]
    is identity(matrix) -> result
}
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
  n:global = 10
  if even() = true {
    1 -> result
  } else {
    0 -> result
  }
}
even: -> boolean {
  if n ~= 0 {
    n - 1 -> n
    odd() -> result
  } else {
    true -> result
  }
}
odd: -> boolean {
  if n ~= 0 {
    n - 1 -> n
    even() -> result
  } else {
    false -> result
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
* `--result`/`-r`: Output the result of the program. (The result value from `entry point`.)
* `--echo-input`/`-e`: Output what was sent in to translate.
* `--graphviz`/`-g`: Generate a graphviz visualization and open it in the default application.
* `--pegdebug`/`-p`: Annotate the grammar with PegDebug before translating.
* `--stop-on-first-error`/`-s`: Stop outputting errors after the first.
* `--verbose`/`-v`: Output detailed information about stage execution.
* `--unpoetic`/`-u`: Suppress poetry.

You can use the format `-{option character}` to select multiple options at a time.
For example, `-vr` will output verbose information and the program result value.

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
