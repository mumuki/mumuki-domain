class Certificate < ApplicationRecord
  include WithGeneratedCode

  belongs_to :user
  belongs_to :certificate_program

  has_one :organization, through: :certificate_program

  delegate :title, :description, :template_html_erb, :background_image_url, to: :certificate_program

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
              certificate_program: { only: [:title, :description] },
              organization: { only: [:name, :display_name] } }).to_deep_struct
  end

  def for_user?(user)
    self.user == user
  end
end
