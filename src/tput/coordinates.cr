class Tput

  # Collection of methods related to coordinates within the terminal screen.
  module Coordinates

    # Gets terminal/screen size as number of columns and rows.
    macro get_screen_size
      r, c = ENV["TPUT_SCREEN_SIZE"]?.try { |s| s.split('x', 2).map &.to_i } ||
        Term::Screen.size_from_ioctl ||
        Term::Screen.size_from_env ||
        Term::Screen.size_from_ansicon ||
        DEFAULT_SCREEN_SIZE
      Log.trace { "@screen_size.height x @screen_size.width = #{r} x #{c}" }
      Size.new c, r
    end

    # Gets terminal/screen size and resets the values in memory to the discovered dimensions.
    def reset_screen_size
      @screen_size = get_screen_size
      _ncoords
      true
    end

    # Makes sure that the cursor position is within screen size by adjusting it if/when necessary.
    #
    # The usual way to use this function is to set cursor position without any particular
    # considerations for the boundaries, and then call `_ncoords` to make sure the cursor
    # is brought back into the screen if it was out of it.
    def _ncoords
      # TODO - instead of adjusting live x/y, make this function accept the proposed x/y as
      # arguments and return them after eventual adjustment. Those values can then be saved
      # to @position.x/y, making sure that the stored values are never out of boundaries.
      if @position.x<0
        @position.x=0
      elsif @position.x > @screen_size.width
        @position.x = @screen_size.width - 1
      end
      if @position.y < 0
        @position.y = 0
      elsif @position.y > @screen_size.height
        @position.y = @screen_size.height - 1
      end
    end
  end
end
