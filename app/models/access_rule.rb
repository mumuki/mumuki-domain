class AccessRule < ApplicationRecord
  self.abstract_class = true

  enum action: %i(hide disable)

  belongs_to :chapter

  alias_attribute :content, :chapter

  def call(content, workspace)
    if match? content, workspace
      hide? ? :private : :protected
    else
      :public
    end
  end

  def match?(content, workspace)
    self.content == content && eval(content, workspace)
  end

  class Always < AccessRule
    self.table_name = 'access_rules'

    def eval(*)
      true
    end
  end

  class At < AccessRule
    self.table_name = 'access_rules'

    def eval(*)
      date.past?
    end
  end

  class Until < AccessRule
    self.table_name = 'access_rules'

    def eval(*)
      !date.past?
    end
  end

  class Unless < AccessRule
    self.table_name = 'access_rules'

    def eval(_content, workspace)
      !workspace.has_role? role
    end
  end
end

