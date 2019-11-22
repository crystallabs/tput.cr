[![Build Status](https://travis-ci.com/crystallabs/tput.svg?branch=master)](https://travis-ci.com/crystallabs/tput)
[![Version](https://img.shields.io/github/tag/crystallabs/tput.svg?maxAge=360)](https://github.com/crystallabs/tput/releases/latest)
[![License](https://img.shields.io/github/license/crystallabs/tput.svg)](https://github.com/crystallabs/tput/blob/master/LICENSE)

# Tput

Tput is a low-level component for building term/console applications in Crystal.

It is closely related to shard [Terminfo](https://github.com/crystallabs/terminfo).
Terminfo parses terminfo files into instances of `Terminfo::Data` or custom classes.

Tput builds on this basic functionality to provide a fully-functional environment.
In addition to using the Terminfo data, it also detects the terminal program and its
known bugs or quirks, and configures itself for outputting the correct escape sequences.

It also provides sensible generic defaults in the case that using Terminfo data is not
desired or appropriate terminfo file cannot be found.

It is implemented natively and does not depend on ncurses or other external library.

## Installation

Add the dependency to `shard.yml`:

```yaml
dependencies:
  tput:
    github: crystallabs/tput
    version: 0.1.0
```

## Usage in a nutshell

Here is a basic example that initializes Tput and checks some of the boolean and numeric capabilities.

```crystal
require "tput"

# With own class
class MyClass
  include Tput
end
my = MyClass.new

# With built-in class
my = Tput::Data.new

# Check whether we are running under an XTerm:
p my.xterm?

# Test a couple boolean capabilities
p my.booleans["needs_xon_xoff"] # Same as ["nxon"] or ["nx"]
p my.booleans["over_strike"]    # Same as ["os"]

# Print a couple numeric values
p my.numbers["columns"]         # Same as ["cols"] or ["co"]
p my.numbers["lines"]           # Same as ["lines"] or ["li"]
```

Tput can also output string capabilities. Most of the string capabilities are
non-parametric and simply output fixed sequences appropriate for current terminal.
However, some also accept integer arguments, such as color pairs or cursor position.

Tput wraps all string capabilities into callable Procs. These Procs can be called at
three levels of abstraction. From lowest to highest:

Directly, returning the escape sequence as a string:

```crystal
NO_ARGS = Array(Int16).new

print my.methods["bell"].call NO_ARGS
print my.methods["carriage_return"].call NO_ARGS
print my.methods["cursor_position"].call 10i16, 20i16
```

Via `#put()`, automatically outputting the sequence to the terminal:

```crystal
my.put "bell"
my.put "cr"
my.put "cursor_address", 10, 20
puts "Hi!"
```

Via object methods, taking into account terminal specifics and state:

```crystal
# Invoke string capabilities via predefined methods (high-level)
my.bell
my.cr
my.cup 10, 20
```

All the methods and capability names have many aliases. For example,
`cursor_position` can be accessed under all full and aliased names and
terminfo and termcap capability names: `cursor_position`, `cursor_pos`,
`cursor_address`, `cup`, `cm`, and `pos`.

## API documentation

Run `crystal docs` as usual, then open file `docs/index.html`.

Also, see examples in the directory `examples/`.

## Testing

Run `crystal spec` as usual.

Also, see examples in the directory `examples/`.

## Thanks

* All the fine folks on FreeNode IRC channel #crystal-lang and on Crystal's Gitter channel https://gitter.im/crystal-lang/crystal

## Other projects

List of interesting or similar projects in no particular order:

- https://github.com/crystallabs/crysterm - Term/console toolkit for Crystal
