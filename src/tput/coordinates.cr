class Tput

  # Collection of methods related to coordinates within the terminal screen.
  module Coordinates
    include Crystallabs::Helpers::Logging

    # Gets terminal/screen size as number of columns and rows.
    def get_screen_size
      r, c = ENV["TPUT_SCREEN_SIZE"]?.try { |s| s.split('x', 2).map &.to_i } ||
        Term::Screen.size_from_ioctl ||
        Term::Screen.size_from_env ||
        Term::Screen.size_from_ansicon ||
        DEFAULT_SCREEN_SIZE
      s = Size.new c, r
      Log.trace { my s }
      s
    end

    # Gets terminal/screen size and resets the values in memory to the discovered dimensions.
    def reset_screen_size
      @screen = get_screen_size
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
      # to @cursor.x/y, making sure that the stored values are never out of boundaries.
      if @cursor.x<0
        @cursor.x=0
      end
      if @cursor.x >= @screen.width
        @cursor.x = @screen.width - 1
      end
      if @cursor.y < 0
        @cursor.y = 0
      end
      if @cursor.y >= @screen.height
        @cursor.y = @screen.height - 1
      end
    end
  end
end
