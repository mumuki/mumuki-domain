class AccessRule < ApplicationRecord
  self.abstract_class = true

  enum action: %i(hide disable)

  belongs_to :chapter

  alias_attribute :content, :chapter

  def call(content)
    visibility_for(self.content == content && eval(content))
  end

  def visibility_for(match)
    if match
      hide? ? :private : :protected
    else
      :public
    end
  end

  class Always < AccessRule
    self.table_name = 'access_rules'

    def eval(_)
      true
    end
  end

  class At < AccessRule
    self.table_name = 'access_rules'

    def eval(_)
      date.past?
    end
  end
end

