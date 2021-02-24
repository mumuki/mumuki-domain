class Certificate < ApplicationRecord
  include WithGeneratedCode

  belongs_to :user
  belongs_to :certification

  has_one :organization, through: :certification

  delegate :title, :description, :template_html_erb, :background_image_url, to: :certification

  def self.code_size
    12
  end

  def filename
    "#{title.parameterize.underscore}.pdf"
  end

  def locals
    as_json(only: [:start_date, :end_date],
            include: {
              user: { methods: [:formal_first_name, :formal_last_name, :formal_full_name] },
              certification: { only: [:title, :description] },
              organization: { only: [:name, :display_name] } }).to_deep_struct
  end

  def for_user?(user)
    self.user == user
  end
end
