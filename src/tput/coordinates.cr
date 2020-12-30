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

    # Generic method used to keep cursor within screen bounds.
    #
    # This function handles both x and y coordinates, even though
    # it is customary to call it with one of those being 0, to
    # effectively only adjust the other coordinate.
    #
    # Since the code for x and y is identical except for the max/bounds
    # value (screen.width vs. screen.height), it would be possible to
    # make this function operate on one coordinate at a time; only the
    # max value (width or height) would have be supplied as an extra argument.
    private def _adjust_xy(x=0, y=0, sx=0, sy=0, wrap=false)
      s=@screen

      # sx/sy are the starting point for calculation.
      # In absolute coords these will be 0.
      # In relative coords these will be @cursor's x/y

      # Delta; by how much the desired x/y must be adjusted.
      dx=0
      dy=0

      # Originally requested x/y, before adjustment.
      ox=x
      oy=y

      # Allow -1 or any -X to count from the far end back.
      # (i.e. x/y=-1/-1 == bottom-right point on the screen)
      if wrap
        x+=@screen.width if x<0
        y+=@screen.height if y<0
      end

      # The would-be absolute position.
      nx=sx+x
      ny=sy+y

      # Check if x is out of bounds and adjust
      if nx < 0
        dx = nx
        x -= nx
      elsif nx >= s.width
        dx = s.width - 1 - nx
        x = s.width - 1 - sx
      end

      # Check if y is out of bounds and adjust
      if ny < 0
        dy = ny
        y -= ny
      elsif ny >= s.height
        dy = s.height - 1 - ny
        y = s.height - 1 - sy
      end

      Log.trace { my sx, sy, ox, oy, x, y, dx, dy }

      # Return the two values that are identical, or replace,
      # the originally requested values.
      {x,y}
    end

    # Returns [x,y] adjusted so that the values are within screen bounds.
    def _adjust_xy_abs(x=0,y=0)
      _adjust_xy x, y, wrap: true
    end

    # Returns [x,y] adjusted so that when added to the cursor's current position, the values are within screen bounds.
    def _adjust_xy_rel(x=0,y=0)
      _adjust_xy x, y, @cursor.x, @cursor.y
    end

  end
end
