require "../src/tput"

my = Tput::Data.new term: "xterm"

pp my.cols
pp my.lines

