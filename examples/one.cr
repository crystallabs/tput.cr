require "unibilium"
require "unibilium-shim"

require "../src/tput"

terminfo = Unibilium::Terminfo.from_env
tput = Tput.new terminfo

tput.set_title "Test 123"

sleep 100
