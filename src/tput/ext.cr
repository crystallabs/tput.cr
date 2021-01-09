struct Char
  def to_json_object_key
    to_s
  end

  def to_json(b : JSON::Builder)
    b.string to_s
  end
end
