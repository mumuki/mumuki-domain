class Certificate < ApplicationRecord
  include WithCode

  belongs_to :user
  belongs_to :certification

  has_one :organization, through: :certification

  delegate :title, :description, :template_html_erb, :background_image_url, to: :certification

  def self.code_size
    12
  end

  def locals
    json = as_json only: [:start_date, :end_date],
                   include: {
                     user: { methods: [:formal_first_name, :formal_last_name, :formal_full_name] },
                     certification: { only: [:title, :description] },
                     organization: { only: [:name, :display_name, :description] }
                   }
    JSON.parse json.to_json, object_class: OpenStruct
  end

end
