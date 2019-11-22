require "../src/tput"

# With own class
class MyClass
  include Tput
end
my = MyClass.new

# With built-in class
my = Tput::Data.new

# Test a couple boolean capabilities
p my.booleans["needs_xon_xoff"] # Same as ["nxon"] or ["nx"]
p my.booleans["over_strike"]    # Same as ["os"]

# Print a couple numeric values
p my.numbers["columns"]         # Same as ["cols"] or ["co"]
p my.numbers["lines"]           # Same as ["lines"] or ["li"]

# Invoke some of the string capabilities directly (low-level)
print my.methods["bell"].call Array(Int16).new
print my.methods["carriage_return"].call Array(Int16).new

# Invoke string capabilities via put() (mid-level)
my.put("cr")
my.put("bell")
my.put("cursor_address", 10, 10)
puts "Hi!"

puts "Making cursor invisible"
my.civis

sleep 1

puts "And doing soft-reset"
my.soft_reset

