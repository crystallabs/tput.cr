module Tput
  module Helpers

  # :nodoc:
  def to_bool(arg : String, empty = false)
    return empty if arg.nil? || arg.empty?
    return false if (arg=="0") || (arg=="false")
    true
  end
  # :nodoc:
  def to_bool(arg : Int)
    arg != 0
  end
  # :nodoc:
  def to_bool(arg, empty = false)
    return empty if arg.nil? || arg.empty?
    raise Exception.new("Unsupported type examined with #to_bool")
  end

  end
end
