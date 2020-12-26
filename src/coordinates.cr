class Tput
  module Coordinates

    macro get_screen_size
      r, c = ENV["TPUT_SCREEN_SIZE"]?.try { |s| s.split('x', 2).map &.to_i } ||
        Term::Screen.size_from_ioctl ||
        Term::Screen.size_from_env ||
        Term::Screen.size_from_ansicon ||
        DEFAULT_SCREEN_SIZE
      Log.trace { "@screen_size.height x @screen_size.width = #{r} x #{c}" }
      Size.new c, r
    end

    def reset_screen_size
      @screen_size.height, @screen_size.width = get_screen_size
      true
    end

    def _ncoords
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
