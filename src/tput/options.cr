require "toka"

class Tput
  class Options
    Toka.mapping({
      force_unicode: {
        type: Bool,
        default: false,
        long: [ "force-unicode", "force_unicode", "unicode", "fu" ],
        short: [ "u" ],
        description: "Force unicode use regardless of detected terminal settings.",
        #value_name: "Y/N",
        category: "Terminal and terminal emulator options",
      },
    }, {
      "banner": "Usage: [options]",
      footer: "",
      #help: "<automatic>",
      colors: true,
    })
  end
end
