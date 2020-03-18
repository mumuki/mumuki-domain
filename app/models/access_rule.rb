class AccessRule < ApplicationRecord
  enum action: %i(hide disable)

  belongs_to :chapter
  belongs_to :organization

  alias_attribute :content, :chapter

  def call(content, workspace)
    if match? content, workspace
      hide? ? :hidden : :disabled
    else
      :enabled
    end
  end

  def match?(content, workspace)
    self.content == content && eval(content, workspace)
  end

  def to_s
    [action, content.slug, to_condition_s].compact.join(' ')
  end

  class Always < AccessRule
    def eval(*)
      true
    end

    def to_condition_s
    end
  end

  class At < AccessRule
    def eval(*)
      date.past?
    end

    def to_condition_s
      "at #{date}"
    end
  end

  class Until < AccessRule
    def eval(*)
      !date.past?
    end

    def to_condition_s
      "until #{date}"
    end
  end

  class Unless < AccessRule
    def eval(_content, workspace)
      !workspace.has_role? role
    end

    def to_condition_s
      "unless #{role}"
    end
  end
end

