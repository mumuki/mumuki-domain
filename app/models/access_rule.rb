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

  def self.compile(expression, organization = Organization.current)
    # todo recompile when reindenxing
    ast = Mumuki::Domain::Parsers::AccessRuleParser.new.parse expression
    klass = ast.delete :class
    grant = ast.delete :grant
    organization.book.chapters
      .select { |it| grant.allows? it.slug }
      .map { |it| klass.new(ast.merge content: it, organization: organization) }
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

  class WhileUnready < AccessRule
    def eval(_content, workspace)
      raise 'pending'
    end

    def to_condition_s
      "while unready"
    end
  end
end

