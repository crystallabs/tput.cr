require "superconf"

# tput's tunables, registered into the shared `Superconf` registry. Because the
# registry is a process-wide singleton, these appear alongside the host
# application's own options in one combined, configurable, dumpable list.
#
# `Tput` reads these as the defaults for the corresponding constructor arguments
# / accessors; explicit arguments to `Tput.new` still override them.
module Superconf
  option "tput.read_timeout", 400.milliseconds,
    description: "Timeout waiting for terminal query replies (probing and key reads)",
    validate: ->(t : Time::Span) { t > Time::Span.zero }
  option "tput.use_buffer", true,
    description: "Buffer Tput output instead of writing each control sequence immediately"
  option "tput.probe", true,
    description: "Auto-probe the terminal for colors/features on Tput.new (when attached to a TTY)"
  option "keyboard.protocol", "auto",
    description: "Enhanced keyboard protocol to use: auto (best supported), or kitty / modify_other_keys / legacy"
  option "keyboard.exclude", "",
    description: "Enhanced keyboard protocols to never use (comma/space separated: kitty, modify_other_keys, legacy)"
end
