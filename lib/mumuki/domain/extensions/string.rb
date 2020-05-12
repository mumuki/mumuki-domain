class String

  # Adds a newline character unless
  # this string is empty or already ends with a newline
  # See https://unix.stackexchange.com/a/18789
  def ensure_newline
    empty? || ends_with?("\n") ? self : self + "\n"
  end

  def friendlish
    I18n.transliterate(self).
      downcase.
      gsub(/[^0-9a-z ]/, '').
      squish.
      gsub(' ', '-')
  end

  def markdown_paragraphs
    split(/\n\s*\n/)
  end

  def normalize_whitespaces
    gsub(/([^[:ascii:]])/) { $1.blank? ? ' ' : $1 }
  end

  def file_extension
    File.extname(self).delete '.'
  end
end


# The nil-safe affable pipeline goes as follow:
#
# i18n > markdownified > sanitized > affable
#
# Where:
#  * i18n: translates to current locale
#  * markdownified: interpretes markdown in message and generates HTML
#  * sanitized: sanitizes results HTML
#  * affable: changes structure to hide low level details
class String
  def affable
    markdownified(one_liner: true).sanitized
  end

  def markdownified(**options)
    Mumukit::ContentType::Markdown.to_html self, options
  end

  def sanitized
    Mumukit::ContentType::Sanitizer.sanitize self
  end
end

class NilClass
  def affable
  end

  def markdownified(**options)
  end

  def sanitized
  end
end
