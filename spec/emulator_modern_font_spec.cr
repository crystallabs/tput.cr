require "./spec_helper"

# `Tput::Emulator.modern_font_env?`: which terminals, by identity, are trusted
# to render the `extended` glyph tier (dingbats, emoji).
describe Tput::Emulator do
  it "recognizes the self-rendering terminals with capable font stacks" do
    Tput::Emulator.modern_font_env?({"KITTY_WINDOW_ID" => "1"}).should be_true
    Tput::Emulator.modern_font_env?({"WEZTERM_PANE" => "1"}).should be_true
    Tput::Emulator.modern_font_env?({"GHOSTTY_RESOURCES_DIR" => "/x"}).should be_true
    Tput::Emulator.modern_font_env?({"ITERM_SESSION_ID" => "w0t0p0"}).should be_true
    Tput::Emulator.modern_font_env?({"TERM_PROGRAM" => "iTerm.app"}).should be_true
    Tput::Emulator.modern_font_env?({"TERM_PROGRAM" => "Apple_Terminal"}).should be_true
  end

  it "does not trust an unidentified or plain terminal" do
    Tput::Emulator.modern_font_env?({} of String => String).should be_false
    Tput::Emulator.modern_font_env?({"TERM" => "xterm-256color"}).should be_false
    Tput::Emulator.modern_font_env?({"TERM_PROGRAM" => "vscode"}).should be_false
  end
end
