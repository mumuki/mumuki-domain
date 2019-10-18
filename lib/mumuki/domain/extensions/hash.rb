class Hash
  def markdownify!(*keys)
    keys.each { |it| self[it] = Mumukit::ContentType::Markdown.to_html(self[it]) }
  end
end
