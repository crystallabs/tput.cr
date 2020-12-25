class Tput
  module Output
    module Scrolling
      include Crystallabs::Helpers::Alias_Methods
      #include Crystallabs::Helpers::Boolean
      include Macros

      # ESC D Index (IND is 0x84).
      def index
        @position.y+=1
        _ncoords
        put(s.ind?) || _write "\x1bD"
      end
      alias_previous ind

      # ESC M Reverse Index (RI is 0x8d).
      def reverseIndex
        @position.y-=1
        _ncoords
        put(s.ri?) || _write "\x1bM"
      end
      alias_previous ri, reverse

      # CSI Ps S  Scroll up Ps lines (default = 1) (SU).
      def scroll_up(param=1)
        @position.y -= param
        _ncoords
        put(s.parm_index?(param)) || _write "\x1b[#{param}S"
      end
      alias_previous su

      # CSI Ps T  Scroll down Ps lines (default = 1) (SD).
      def scroll_down(param=1)
        @position.y += param
        _ncoords
        put(s.parm_rindex?(param)) || _write "\x1b[#{param}T"
      end
      alias_previous sd

      # CSI Ps ; Ps r
      #   Set Scrolling Region [top;bottom] (default = full size of win-
      #   dow) (DECSTBM).
      # CSI ? Pm r
      def set_scroll_region(top=nil, bottom=nil)
        unless @position.zero_based?
          top = (top || 1) - 1
          bottom = (bottom || @screen_size.height) - 1
        else
          top = top || 0
          bottom = bottom || (@screen_size.height - 1)
        end
        @scroll_top = top
        @scroll_bottom = bottom
        @position.x = 0
        @position.y = 0
        _ncoords
        put(s.csr?(top,bottom)) || _write "\x1b[#{top+1};#{bottom+1}r"
      end
      alias_previous decstbm, csr

    end
  end
end
