class Array
  def insert_last(element)
    self + [element]
  end

  def single
    first if single?
  end

  def single!
    raise 'There is more than one element' unless single?
    first
  end

  def single?
    size == 1
  end

  def multiple?
    size > 1
  end

  def randomize_with(randomizer, seed)
    map { |it| it.randomize_with randomizer, seed }
  end

  def to_deep_struct
    map { |val| (val.is_a?(Hash) || val.is_a?(Array)) ? val.to_deep_struct : val }
  end

end
