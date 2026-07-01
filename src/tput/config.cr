require "superconf"

# tput's tunables, registered into the shared `Superconf` registry (a
# process-wide singleton), so they appear alongside the host application's own
# options in one combined list.
#
# `Tput` uses these as defaults for the corresponding constructor args/accessors;
# explicit `Tput.new` arguments still override them.
module Superconf
  option "tput.read_timeout", 400.milliseconds,
    description: "Timeout waiting for terminal query replies (probing and key reads)",
    validate: ->(t : Time::Span) { t > Time::Span.zero }
  option "tput.use_buffer", true,
    description: "Buffer Tput output instead of writing each control sequence immediately"
  option "tput.probe", true,
    description: "Auto-probe the terminal for colors/features on Tput.new (when attached to a TTY)"
  option "tput.attr_cache_limit", 4096,
    description: "Max cached SGR attribute sequences before FIFO eviction; 0 disables the attribute cache",
    validate: ->(n : Int32) { n >= 0 }
  option "keyboard.protocol", "auto",
    description: "Enhanced keyboard protocol to use: auto (best supported), or kitty / modify_other_keys / legacy"
  option "keyboard.exclude", "",
    description: "Enhanced keyboard protocols to never use (comma/space separated: kitty, modify_other_keys, legacy)"
end
