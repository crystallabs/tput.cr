class Tput
  module CoordinateSystem
    @rows : Int32
    @cols : Int32

    @x = 0
    @y = 0

    @zero_based = false

    macro get_screen_size
      r, c = ENV["TPUT_SCREEN_SIZE"]?.try { |s| s.split('x', 2).map &.to_i } ||
        Term::Screen.size_from_ioctl ||
        Term::Screen.size_from_env ||
        Term::Screen.size_from_ansicon ||
        DEFAULT_SCREEN_SIZE
      Log.trace { "@rows x @cols = #{r} x #{c}" }
      {r,c}
    end

    def reset_screen_size
      @rows, @cols = get_screen_size
      true
    end

    def _ncoords
      if @x<0
        @x=0
      elsif @x > @cols
        @x = @cols -1
      end
      if @y < 0
        @y = 0
      elsif @y > @rows
        @y = @rows -1
      end
    end
  end
end
