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

  def template_locals
    { user: user,
      certificate_program: certificate_program,
      organization: organization,
      certificate: self }
  end

  def for_user?(user)
    self.user == user
  end
end
