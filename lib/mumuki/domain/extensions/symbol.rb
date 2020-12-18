class Symbol
  def randomize_with(randomizer, seed)
    self.to_s.randomize_with(randomizer, seed).to_sym
  end
end
