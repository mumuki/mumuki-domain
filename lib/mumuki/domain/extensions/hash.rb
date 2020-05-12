class Hash
  def markdownify!(*keys, **options)
    warn "Don't use markdownify. Use markdownified! instead"
    markdownified! *keys, **options
  end

  def markdownified!(*keys, **options)
    keys.each { |it| self[it] = self[it].markdownified }
  end

  def markdownified(*keys, **options)
    map { |k, v| key.in?(keys) ? v.markdownified(options) : v }.to_h
  end
end
