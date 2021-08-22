require "unibilium"
require "unibilium-shim"

require "../src/tput"

terminfo = Unibilium::Terminfo.from_env
tput = Tput.new terminfo

tput.title = "Test 123"

sleep 100
