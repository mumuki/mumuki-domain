# Concern for augmenting exercise
# content with guide parent fields
module WithAugmentation
  extend ActiveSupport::Concern

  def expectations
    own_expectations + guide.expectations
  end

  def custom_expectations
    "#{own_custom_expectations}\n#{guide.custom_expectations}"
  end

  def extra(*)
    [guide.extra, super]
      .compact
      .join("\n")
      .strip
      .ensure_newline
  end
end
