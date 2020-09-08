class Time
  def round_years_since(another_time)
    (self.to_s(:number).to_i - another_time.to_s(:number).to_i) / 10e9.to_i
  end
end
