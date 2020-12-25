class Tput
  module Macros
    macro put(arg)
      @shim.try { |s| {{arg}}.try { |data| _write data }}
    end
  end
end
