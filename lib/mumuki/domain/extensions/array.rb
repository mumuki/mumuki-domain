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
end

class NilClass
  def insert_last(element)
    [element]
  end
end
