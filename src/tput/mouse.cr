class Tput
  # Normalized mouse handling.
  #
  # Defines the terminal-agnostic `Mouse::Event` produced when parsing
  # xterm-style mouse reporting sequences (see `Tput::Input#listen`). Meant as
  # the common currency for any mouse source: applications layered on top of
  # Tput (e.g. Crysterm) convert other sources (e.g. the Linux console `gpm`
  # daemon) into this same struct.
  #
  # On-the-wire encodings understood (see `Tput::Input`):
  #
  #   * X10 / "normal" (`\e[M Cb Cx Cy`), where each byte is its value plus 32.
  #     This is the legacy encoding and cannot represent coordinates past
  #     column/row 223 reliably. The VTE byte-overflow quirk is corrected.
  #   * SGR (`\e[< Cb ; Cx ; Cy M|m`), the modern extended encoding (DEC private
  #     mode 1006). The final byte is `M` for a press/motion and `m` for a
  #     release. This is the encoding Tput enables by default and therefore the
  #     primary path.
  #   * URxvt (`\e[ Cb ; Cx ; Cy M`, mode 1015) — like X10 but with decimal
  #     parameters, so it escapes the 223 coordinate limit without SGR's
  #     unambiguous release.
  #   * DEC locator (`\e[ Cb ; Cx ; Cy ; Cp & w`) — VT420 locator event reports.
  #   * vt300 (`\e[ 24 Cb ~ [ Cx , Cy ] \r`).
  #   * Focus in/out (`\e[I` / `\e[O`, mode 1004), surfaced as `Action::Focus`
  #     / `Action::Blur`.
  module Mouse
    # The kind of mouse action a given `Event` represents.
    enum Action
      Down
      Up
      Move
      WheelUp
      WheelDown
      # Terminal focus gained/lost (DEC private mode 1004). Not mouse positions,
      # but reported through the same channel by xterm, so they share the
      # `Event` type. Carry no button or coordinates.
      Focus
      Blur
    end

    # Which button an `Event` pertains to. `None` is used for motion/release
    # reports that carry no meaningful button, `Unknown` for anything we cannot
    # map (e.g. a fourth/fifth button).
    enum Button
      None
      Left
      Middle
      Right
      Unknown
    end

    # A single, normalized mouse event.
    #
    # `x`/`y` are **0-based** screen coordinates (column, row); the on-the-wire
    # 1-based values have already been adjusted.
    struct Event
      property action : Action
      property button : Button
      property x : Int32
      property y : Int32
      property? shift : Bool
      property? meta : Bool
      property? ctrl : Bool

      # Page number, only set by the DEC-locator encoding; `nil` otherwise.
      property page : Int32?

      # Sub-cell pixel coordinates, **0-based**, only set by the SGR-Pixels
      # encoding (DEC private mode 1016); `nil` for every other encoding. When
      # present, `x`/`y` still carry the derived cell coordinates (pixel ÷ cell
      # size), so existing cell-based hit-testing is unaffected — a consumer
      # wanting sub-cell precision (paint/drag over pixel graphics) reads
      # `px`/`py`.
      property px : Int32?
      property py : Int32?

      # Where the event originated: `:xterm` for sequences parsed from the input
      # stream, other producers (e.g. `:gpm`) set their own tag. Informational only.
      property source : Symbol

      def initialize(
        @action : Action,
        @button : Button,
        @x : Int32,
        @y : Int32,
        @shift : Bool = false,
        @meta : Bool = false,
        @ctrl : Bool = false,
        @source : Symbol = :xterm,
        @page : Int32? = nil,
        @px : Int32? = nil,
        @py : Int32? = nil,
      )
      end

      # Whether this is a focus-gained/lost event rather than a pointer event.
      def focus_event?
        action.focus? || action.blur?
      end

      # Constructs a terminal focus-in (`Action::Focus`) event.
      def self.focus(source : Symbol = :xterm) : Event
        new Action::Focus, Button::None, 0, 0, source: source
      end

      # Constructs a terminal focus-out (`Action::Blur`) event.
      def self.blur(source : Symbol = :xterm) : Event
        new Action::Blur, Button::None, 0, 0, source: source
      end
    end

    # Decodes the common xterm "Cb" button byte (shared by the X10 and SGR
    # encodings) into `{action, button, shift, meta, ctrl}`.
    #
    # Bit layout of *cb*:
    #   * bits 0-1 : button (0 = left, 1 = middle, 2 = right, 3 = none/release)
    #   * bit  2   : shift
    #   * bit  3   : meta (alt)
    #   * bit  4   : control
    #   * bit  5   : motion (a drag/move report rather than a click)
    #   * bit  6   : wheel (then bit 0 selects up=0 / down=1)
    #   * bit  7   : extra button (8-11, e.g. back/forward) — reported as Unknown
    #
    # *released* is supplied by the caller when the encoding itself signals a
    # release independently of the button bits (SGR's trailing `m`); for X10 a
    # release is encoded as button bits == 3.
    def self.decode_button(cb : Int32, released : Bool = false) : Tuple(Action, Button, Bool, Bool, Bool)
      shift = (cb & 4) != 0
      meta = (cb & 8) != 0
      ctrl = (cb & 16) != 0

      # Wheel events use bit 6; the low bit then selects the direction.
      if (cb & 64) != 0
        action = (cb & 1) == 0 ? Action::WheelUp : Action::WheelDown
        return {action, Button::None, shift, meta, ctrl}
      end

      # Extra buttons (8-11, e.g. the back/forward side buttons) set bit 7; the
      # low button bits then no longer mean Left/Middle/Right, so report them as
      # Unknown rather than mis-mapping a back click onto a left click.
      button = if (cb & 128) != 0
                 Button::Unknown
               else
                 case cb & 3
                 when 0 then Button::Left
                 when 1 then Button::Middle
                 when 2 then Button::Right
                 else        Button::None
                 end
               end

      # Order matters. SGR signals a release explicitly (trailing `m`); a motion
      # report sets bit 5, even when the button bits are 3 ("no button" during a
      # mode-1003 move) — so motion must be checked before interpreting button
      # bits == 3 as an X10 release.
      action = if released
                 Action::Up
               elsif (cb & 32) != 0
                 Action::Move
               elsif (cb & 3) == 3
                 Action::Up
               else
                 Action::Down
               end

      {action, button, shift, meta, ctrl}
    end

    # Parses an X10 / "normal" encoded event. *cb*, *cx*, *cy* are the three raw
    # bytes following `\e[M`, each still carrying the +32 bias.
    #
    # Corrects the buggy-VTE coordinate overflow: VTE can only send unsigned
    # chars, so a coordinate whose `+32`-biased byte exceeds 255 wraps modulo
    # 256, landing below the normal `0x20` floor. A raw byte under `0x20` is
    # unwrapped by adding a full 256 cycle to recover the original biased byte.
    # (Adding 0xff, as before, lands one short and decodes every wrapped
    # coordinate one cell too low.)
    def self.parse_x10(cb : Int32, cx : Int32, cy : Int32) : Event
      cx += 256 if cx < 0x20
      cy += 256 if cy < 0x20
      action, button, shift, meta, ctrl = decode_button(cb - 32)
      Event.new action, button, (cx - 32 - 1), (cy - 32 - 1), shift, meta, ctrl
    end

    # Parses an SGR (1006) encoded event. *cb*, *cx*, *cy* are the decimal
    # parameters from `\e[< Cb ; Cx ; Cy`, and *final* is the terminating byte
    # (`'M'` press/motion, `'m'` release).
    def self.parse_sgr(cb : Int32, cx : Int32, cy : Int32, final : Char) : Event
      action, button, shift, meta, ctrl = decode_button(cb, released: final == 'm')
      Event.new action, button, (cx - 1), (cy - 1), shift, meta, ctrl
    end

    # Parses an SGR-Pixels (DEC private mode 1016) encoded event. The wire
    # format is identical to SGR (1006) — `\e[< Cb ; Cx ; Cy M|m` — but *cx*/*cy*
    # are **pixel** coordinates, not cells. *cell_w*/*cell_h* are the terminal's
    # cell size in pixels (from `Tput#mouse_cell_pixels`); they derive the cell
    # coordinates carried on `x`/`y` while the raw 0-based pixels are kept on
    # `px`/`py`. A non-positive cell size (unknown, e.g. under a multiplexer)
    # degrades gracefully: the pixel value is used directly as the cell value
    # rather than dividing by zero.
    def self.parse_sgr_pixels(cb : Int32, cx : Int32, cy : Int32, final : Char,
                              cell_w : Int32, cell_h : Int32) : Event
      action, button, shift, meta, ctrl = decode_button(cb, released: final == 'm')
      px = cx - 1
      py = cy - 1
      x = cell_w > 0 ? px // cell_w : px
      y = cell_h > 0 ? py // cell_h : py
      Event.new action, button, x, y, shift, meta, ctrl, px: px, py: py
    end

    # Parses a URxvt (mode 1015) encoded event. *cb*, *cx*, *cy* are the decimal
    # parameters from `\e[ Cb ; Cx ; Cy M`. Like X10, *cb* carries the +32 bias
    # and there is no explicit release distinction; unlike X10 the coordinates
    # are decimal and unbounded.
    def self.parse_urxvt(cb : Int32, cx : Int32, cy : Int32) : Event
      # Work around a urxvt bug that reports 128/129 instead of 96/97 for a
      # wheel up/down during motion. Map back to the proper +32-biased wheel
      # values (96 = up, 97 = down) so `decode_button` still sees the wheel bit
      # and correct direction after the bias is stripped. (The previous `cb = 67`
      # lost the direction and cleared the wheel bit, mis-decoding as motion.)
      cb = 96 if cb == 128
      cb = 97 if cb == 129
      action, button, shift, meta, ctrl = decode_button(cb - 32)
      Event.new action, button, (cx - 1), (cy - 1), shift, meta, ctrl
    end

    # Parses a DEC-locator event report (`\e[ Pe ; Pb ; Pr ; Pc [; Pp] & w`).
    # The caller maps the wire fields to these arguments: *cb* = `Pe` locator
    # event code, *cx* = `Pc` column, *cy* = `Pr` row, *cp* = `Pp` page (1 when
    # the terminal omits it, as xterm does). The button-state mask `Pb` is not
    # currently surfaced.
    #
    # Each button has a press/release pair of codes (even = press, odd =
    # release): 2/3 = left, 4/5 = middle, 6/7 = right.
    def self.parse_dec(cb : Int32, cx : Int32, cy : Int32, cp : Int32) : Event
      # Earlier code recognized only the left release (3), mis-decoding
      # middle/right releases as presses and dropping button identity.
      button = case cb
               when 2, 3 then Button::Left
               when 4, 5 then Button::Middle
               when 6, 7 then Button::Right
               else           Button::Unknown
               end
      action = cb.odd? ? Action::Up : Action::Down
      Event.new action, button, (cx - 1), (cy - 1), page: cp
    end

    # Parses a vt300 event report (`\e[ 24 Cb ~ [ Cx , Cy ] \r`). *cb* selects
    # the button (1 = left, 2 = middle, 5 = right); the report is always a press.
    def self.parse_vt300(cb : Int32, cx : Int32, cy : Int32) : Event
      button = case cb
               when 1 then Button::Left
               when 2 then Button::Middle
               when 5 then Button::Right
               else        Button::Unknown
               end
      Event.new Action::Down, button, (cx - 1), (cy - 1)
    end
  end
end
