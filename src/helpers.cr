module Tput
  module Helpers

    # :nodoc:
    def to_bool(arg : String, empty = nil)
      return empty if !empty.nil? && (arg.nil? || arg.empty?)
      #return false if (arg.size==0) || (arg=="0") || (arg[0]=="f")
      return true if (arg=="1") || (arg[0]=="t")
      #true
      false
    end
    # :nodoc:
    def to_bool(arg : Int)
      arg != 0
    end
    # :nodoc:
    def to_bool(arg : Char, empty = nil)
      to_bool arg.to_s
    end
    # :nodoc:
    def to_bool(arg, empty = nil)
      #raise Exception.new("Unsupported value ('#{arg}') examined with #to_bool")
      return empty if !empty.nil? && (arg.nil? || arg.empty?)
      false
    end

  end
end
