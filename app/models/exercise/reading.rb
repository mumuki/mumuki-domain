class Reading < Exercise
  include Confirmable

  name_model_as Exercise

  def layout
    :input_bottom
  end

  def input_kids?
    false
  end

  def layout=(layout)
    raise 'can not set a layout different to input_bottom on readings' unless layout.like? :input_bottom
  end

  def queriable?
    false
  end
end
