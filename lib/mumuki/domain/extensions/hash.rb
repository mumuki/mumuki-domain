class Hash
  def markdownify!(*keys, **options)
    warn "Don't use markdownify. Use markdownified! instead"
    markdownified! *keys, **options
  end

  def markdownified!(*keys, **options)
    keys.each { |it| self[it] = self[it].markdownified(**options) }
  end

  def markdownified(*keys, **options)
    map { |k, v| key.in?(keys) ? v.markdownified(options) : v }.to_h
  end

  def randomize_with(randomizer, seed)
    transform_values { |v| v.randomize_with randomizer, seed }
  end
end
