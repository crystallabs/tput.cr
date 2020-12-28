require "unibilium"
require "unibilium-shim"

require "../src/tput"

terminfo = Unibilium::Terminfo.from_env
tput = Tput.new terminfo

puts "Check your xterm/rxvt title. It should say Test 123.
If it is not, open  src/tput/output.cr at line 177 and 
prefix the @_buf argument with 'io: ... '.

Then the title will get changed.

I am assuming this is because of the wrong overload for
join() being called?

Press ctrl+c to exit."

tput.set_title "Test 123"

sleep 100

