require "../src/tput"

my = Tput::Data.new

puts "Making cursor invisible"
my.put "cursor_invisible"
sleep 1

puts "Making cursor visible"
my.put "cursor_visible"

puts "Moving to absolute position 10, 20 on the screen"
my.cursor_address 10, 20

puts "Hello, World!"
