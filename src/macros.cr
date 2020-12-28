class Tput
  module Macros

    # Outputs a string capability to the designated `@output`, if
    # the capability exists.
    #
    # For this macro to work, the Tput instance needs to be
    # initialized with Terminfo data. If Terminfo data is not
    # present, nil will be returned.
    #
    # A common way to call this macro is to allow both the Terminfo
    # data and a particular capability to be missing, such as:
    #
    # ```
    # put(s.smcup?)
    #
    # put(s.cursor_pos?(10, 20))
    #
    # ```
    macro put(arg)
      @shim.try { |s| {{arg}}.try { |data| _write data }}
    end

  end
end
