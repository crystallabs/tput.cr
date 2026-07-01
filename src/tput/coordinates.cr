class Tput
  # Collection of methods related to coordinates within the terminal screen.
  module Coordinates
    include Crystallabs::Helpers::Logging

    # Gets terminal/screen size as number of columns and rows.
    def get_screen_size
      r, c = ENV["TPUT_SCREEN_SIZE"]?.try { |s|
        # Requires well-formed "<rows>x<cols>" with both dimensions positive;
        # malformed input falls through to real detection. `0` is truthy in
        # Crystal, so the explicit `> 0` check is needed to avoid a degenerate
        # `Size` that would break cursor clamping in `#_ncoords`.
        nums = s.split('x', 2).map &.to_i?
        if nums.size == 2 && (rr = nums[0]) && (cc = nums[1]) && rr > 0 && cc > 0
          {rr, cc}
        end
      } ||
             # Query this terminal's own output fd, so multiple `Tput`s on
             # different terminals each get their real dimensions (unlike
             # `Term::Screen.size`, which probes STDIN/STDOUT/STDERR).
             Term::Screen.size_from_ioctl(@output) ||
             # Global STDIN/STDOUT/STDERR probe — only valid when @output is
             # itself a terminal; otherwise it'd return an unrelated
             # controlling terminal's size, so skip to the default instead.
             (output_tty? ? Term::Screen.size : nil) ||
             {DEFAULT_SCREEN_SIZE.height, DEFAULT_SCREEN_SIZE.width}
      s = Size.new c, r
      Log.trace { my s }
      s
    end

    # Whether this `Tput`'s `@output` is connected to a terminal. `false` for any
    # output that can't report it (e.g. `IO::Memory`, which has no `tty?`).
    private def output_tty?
      (out = @output).responds_to?(:tty?) && out.tty?
    end

    # Gets terminal/screen size and resets the values in memory to the discovered dimensions.
    def reset_screen_size
      @screen = get_screen_size
      _ncoords
      true
    end

    # Clamps `@cursor` to screen bounds.
    #
    # Typical usage: set cursor position without worrying about bounds, then
    # call `_ncoords` to bring it back into the screen if needed.
    def _ncoords
      # TODO - instead of adjusting live x/y, make this function accept the proposed x/y as
      # arguments and return them after eventual adjustment. Those values can then be saved
      # to @cursor.x/y, making sure that the stored values are never out of boundaries.
      if @cursor.x < 0
        @cursor.x = 0
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

    # Computes (rather than applies) bounds-adjusted x/y, unlike `#_ncoords`
    # which clamps `@cursor` in place. Handles both axes, though it's typically
    # called with one of x/y at 0 to adjust only the other. Supports negative
    # x/y as offsets from the right/bottom edge, and checks against (0,0) as
    # well as (screen.width, screen.height).
    private def _adjust_xy(x = 0, y = 0, sx = 0, sy = 0, wrap = false)
      s = @screen

      # sx/sy: starting point for calculation (0 for absolute, @cursor's x/y for relative).

      # Originally requested x/y, before adjustment.
      ox = x
      oy = y

      # Allow -1 or any -X to count from the far end back.
      # (i.e. x/y=-1/-1 == bottom-right point on the screen)
      if wrap
        x += @screen.width if x < 0
        y += @screen.height if y < 0
      end

      # x and y are bounds-checked identically (differing only in start offset
      # and bound), so a single helper handles one axis at a time. `dx`/`dy`
      # are the deltas by which x/y had to be adjusted.
      x, dx = _adjust_axis x, sx, s.width
      y, dy = _adjust_axis y, sy, s.height

      Log.trace { my sx, sy, ox, oy, x, y, dx, dy }

      {x, y}
    end

    # Bounds-checks a single coordinate. Given the requested offset `v`, the
    # starting point `s` (0 for absolute, the cursor position for relative) and
    # the screen bound `max` (width or height), returns `{adjusted_v, delta}`
    # where `adjusted_v` keeps the absolute position `s + v` within `0..max-1`
    # and `delta` is how far out of bounds the original would-be position was.
    private def _adjust_axis(v, s, max)
      n = s + v # would-be absolute position
      if n < 0
        {v - n, n}
      elsif n >= max
        {max - 1 - s, max - 1 - n}
      else
        {v, 0}
      end
    end

    # Returns [x,y] adjusted to within screen bounds.
    def _adjust_xy_abs(x = 0, y = 0)
      _adjust_xy x, y, wrap: true
    end

    # Returns [x,y] adjusted so that, added to the cursor's position, the result stays within screen bounds.
    def _adjust_xy_rel(x = 0, y = 0)
      _adjust_xy x, y, @cursor.x, @cursor.y
    end
  end
end
