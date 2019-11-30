require "../src/tput"

# With own class
class MyClass
  include Tput
end
my = MyClass.new(use_buffer: false)

# Check whether we are running under an XTerm:
p my.xterm?

# Test a couple boolean capabilities
p my.booleans["needs_xon_xoff"] # Same as ["nxon"] or ["nx"]
p my.booleans["over_strike"]    # Same as ["os"]

# Print a couple numeric values
p my.numbers["columns"]         # Same as ["cols"] or ["co"]
p my.numbers["lines"]           # Same as ["lines"] or ["li"]

10.times do |i|
  my.rmove 1, -1
  my.print i.to_s
  sleep 0.5
end
