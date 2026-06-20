require "unibilium"
require "unibilium-shim"

require "../src/tput"

# Dumps all detected terminal emulator and feature information, together with a
# description of *how* each value was determined (environment variable,
# terminfo capability, constructor option, live probing, or a default).
#
# Everything is printed as a single, column-aligned list (emulator flags first,
# then static features, then live-probed features), laid out to fit within an
# 80-column terminal.
#
# Usage:
#   crystal run examples/dump.cr                  # human-readable report
#   crystal run examples/dump.cr -- --full        # don't truncate to 80 cols
#   crystal run examples/dump.cr -- --json        # machine-readable JSON
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
  exit
end

# Flatten every detection (emulator flags, then static + probed features) into
# one ordered list of {name, value, source} rows.
rows = [] of {String, String, String}
tput.detections.each_value do |group|
  group.each { |name, d| rows << {name, d.value, d.source} }
end

WIDTH = 80
GAP   = "  "

# `--full` keeps every value/source intact (long lines wrap); the default trims
# each row to fit within 80 columns.
full = ARGV.includes?("--full")

# Truncate *s* to *w* columns, marking elided text with an ellipsis (unless
# `--full` was given, in which case *s* is returned unchanged).
truncate = ->(s : String, w : Int32) { full || s.size <= w ? s : "#{s[0, w - 1]}…" }

# Column widths, sized to the data but capped so a full row fits in 80 columns.
name_w  = {rows.map(&.[0].size).max, "SETTING".size}.max
value_w = { {rows.map(&.[1].size).max, 20}.min, "VALUE".size }.max
src_w   = WIDTH - name_w - value_w - GAP.size * 2

row = ->(a : String, b : String, c : String) do
  puts "#{a.ljust(name_w)}#{GAP}#{b.ljust(value_w)}#{GAP}#{c}"
end

row.call "SETTING", "VALUE", "SOURCE"
row.call "-" * name_w, "-" * value_w, "-" * src_w
rows.each do |(name, value, source)|
  row.call truncate.call(name, name_w),
    truncate.call(value, value_w),
    truncate.call(source, src_w)
end
