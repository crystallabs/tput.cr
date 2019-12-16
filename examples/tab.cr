require "../src/tput"

# With own class
class MyClass
  include Tput
end
my = MyClass.new(use_buffer: false)

# Check whether we are running under an XTerm:
my.print "x"
my.tab
my.print "y"
my.tab
my.print "z"
puts
