require "unibilium"
require "unibilium-shim"

require "../src/tput"

# Dumps all detected terminal emulator and feature information, together with a
# description of *how* each value was determined (environment variable,
# terminfo capability, constructor option, live probing, or a default).
#
# Usage:
#   crystal run examples/dump.cr            # human-readable report
#   crystal run examples/dump.cr -- --json  # machine-readable JSON
#
# Run it from a real terminal to see the live-probed values (default
# foreground/background, palette, ambiguous-character width, DA1 attributes).
# When stdout/stdin isn't a TTY (e.g. piped), probing is skipped and those
# fields read "(not probed)".

terminfo = Unibilium.from_env

# `probe: true` (the default) auto-probes the terminal during construction when
# both ends are a TTY; it's a no-op otherwise.
tput = Tput.new terminfo

if ARGV.includes?("--json")
  puts tput.detections.to_pretty_json
else
  tput.dump
end
