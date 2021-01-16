# Tput.cr

Tput (akin to `tput(1)`) is a complete term/console output library for Crystal.

In general, when writing console apps, 4 layers can be identified:

1. Low-level (terminal emulator & terminfo)
1. Mid-level (console interface, memory state, cursor position, etc.)
1. High-level (a framework or toolkit)
1. End-user apps

Tput implements levels (1) and (2).

It is a Crystal-native implementation (except for binding to a C Terminfo library
called `unibilium`). Not even ncurses bindings are used; Tput is a standalone
library that implements all the needed functions itself and provides a much nicer
API.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  tput:
    github: crystallabs/tput.cr
```

2. Run `shards install`

## Overview

If/when initialized with term name, terminfo data will be looked up. If no terminfo
data is found (or one wishes not to use terminfo), Tput's built-in replacements will
be used.

As part of initialization, Tput will also detect terminal features and the
terminal emulator program in use.

There is zero configuration or considerations to have in mind when using
this library. Everything is set up automatically.

For example:

```cr
require "unibilium"
require "tput"

terminfo = Unibilium::Terminfo.from_env
tput = Tput.new terminfo

# Print detected features and environment
p tput.features.to_json
p tput.emulator.to_json
```

Why no ncurses? Ncurses is an implementation sort-of specific to C. When not working
in C, many of the ncurses methods make no sense; also in general ncurses API is arcane.

## API documentation

Run `crystal docs` as usual, then open file `docs/index.html`.

## Testing

Run `crystal spec` as usual.

## Thanks

* All the fine folks on FreeNode IRC channel #crystal-lang and on Crystal's Gitter channel https://gitter.im/crystal-lang/crystal

* Blacksmoke16, Asterite, HertzDevil, Raz, Oprypin, Straight-shoota, Watzon, Naqvis, and others!
