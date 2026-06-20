class Tput
  # Normalized mouse handling.
  #
  # This module defines the terminal-agnostic `Mouse::Event` produced when
  # parsing xterm-style mouse reporting sequences (see `Tput::Input#listen`).
  # The same `Event` type is intended to be the common currency for *any* mouse
  # source: applications layered on top of Tput (e.g. Crysterm) convert their
  # other sources — such as the Linux console `gpm` daemon — into this same
  # struct, so that all mouse input can flow through a single mechanism.
  #
  # Two on-the-wire encodings are understood:
  #
  #   * X10 / "normal" (`\e[M Cb Cx Cy`), where each byte is its value plus 32.
  #     This is the legacy encoding and cannot represent coordinates past
  #     column/row 223 reliably.
  #   * SGR (`\e[< Cb ; Cx ; Cy M|m`), the modern extended encoding (DEC private
  #     mode 1006). The final byte is `M` for a press/motion and `m` for a
  #     release. This is the encoding Tput enables and therefore the primary
  #     path; X10 parsing exists as a fallback.
  module Mouse
    # The kind of mouse action a given `Event` represents.
    enum Action
      Down
      Up
      Move
      WheelUp
      WheelDown
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

      # Where the event originated. `:xterm` for sequences parsed from the input
      # stream; other producers (e.g. `:gpm`) set their own tag. Purely
      # informational, useful for debugging.
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
      )
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

      button = case cb & 3
               when 0 then Button::Left
               when 1 then Button::Middle
               when 2 then Button::Right
               else        Button::None
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
    def self.parse_x10(cb : Int32, cx : Int32, cy : Int32) : Event
      action, button, shift, meta, ctrl = decode_button(cb - 32)
      Event.new action, button, (cx - 32 - 1), (cy - 32 - 1), shift, meta, ctrl, :xterm
    end

    # Parses an SGR (1006) encoded event. *cb*, *cx*, *cy* are the decimal
    # parameters from `\e[< Cb ; Cx ; Cy`, and *final* is the terminating byte
    # (`'M'` press/motion, `'m'` release).
    def self.parse_sgr(cb : Int32, cx : Int32, cy : Int32, final : Char) : Event
      action, button, shift, meta, ctrl = decode_button(cb, released: final == 'm')
      Event.new action, button, (cx - 1), (cy - 1), shift, meta, ctrl, :xterm
    end
  end
end
