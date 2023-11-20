# Tput.cr

Tput (akin to `tput(1)`) is a complete term/console output library for Crystal.

In general, when writing console apps, 4 layers can be identified:

1. Low-level (terminal emulator & terminfo)
1. Mid-level (console interface, memory state, cursor position, etc.)
1. High-level (a framework or toolkit)
1. End-user apps

Tput implements levels (1) and (2).

Is it any good? Yes, there are many, many functions supported. Check the API
docs for a list.

It is a Crystal-native implementation (except for binding to a C Terminfo library
called `unibilium`). Not even ncurses bindings are used; Tput is a standalone
library that implements all the needed functions itself and provides a much nicer
API.

Why no ncurses? Ncurses is an implementation sort-of specific to C. When not working
in C, many of the ncurses methods make no sense. Also in general, the ncurses API is arcane.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  tput:
    github: crystallabs/tput.cr
    version: ~> 1.0
```

2. Run `shards install`

## Overview

If/when initialized with term name, terminfo data will be looked up. If no terminfo
data is found (or one wishes not to use terminfo), Tput's built-in, generic sequences
will be used.

As part of initialization, Tput will also detect terminal features and the
terminal emulator program in use.

There is zero configuration or considerations to have in mind when using
this library. Everything shoud be set up automatically.

For example:

```cr
require "unibilium"
require "tput"

terminfo = Unibilium::Terminfo.from_env
tput = Tput.new terminfo

# Set terminal emulator's title, if possible
tput.title = "Test 123"

# Set cursor to red block
tput.cursor_shape Tput::CursorShape::Block, blink: false
tput.cursor_color Tput::Color::Red

# Switch to "alternate buffer"
tput.alternate
tput.clear

# Print detected features and environment
puts "Term type and features:"
puts tput.emulator.to_json
puts tput.features.to_json

# Print some more text
tput.cursor_pos 15, 20
tput.echo "Text at position y=15, x=20"
tput.bell
tput.cr
tput.lf

# Enter ACS mode, print some ACS chars, and exit ACS mode
tput.echo "Now displaying ACS chars:"
tput.cr
tput.lf
tput.smacs
tput.echo "``aaffggiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~"
tput.rmacs

tput.cr
tput.lf
tput.echo "Press keys to see their inspected value; press q to exit."
tput.cr
tput.lf

# Listen for keypresses
tput.listen do |char, key, sequence|
  # `char` is a single typed character, or the first character
  # of a sequence which led to a particular key.

  # `key` is a keyboard key, if any. Ordinary characters like
  # 'a' or '1' don't have a representation as Key. Special
  # keys like Enter, F1, Esc etc. do.

  # Sequence is the complete sequence of characters which
  # were consumed as part of identifying the key that was
  # pressed.
  if char == 'q'
    break
  else
    tput.cr
    tput.lf
    tput.echo "Char=#{char.inspect}, Key=#{key.inspect}, Sequence=#{sequence.inspect}"
  end
end

tput.clear
```

## API documentation

Run `crystal docs` as usual, then open file `docs/index.html`.

## Testing

Run `crystal spec` as usual.

## Thanks

* All the fine folks on Libera.Chat IRC channel #crystal-lang and on Crystal's Gitter channel https://gitter.im/crystal-lang/crystal

* Blacksmoke16, Asterite, HertzDevil, Raz, Oprypin, Straight-shoota, Watzon, Naqvis, and others!
