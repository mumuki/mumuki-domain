class Certificate < ApplicationRecord
  belongs_to :user
  belongs_to :certification

  has_one :organization, through: :certification

  def locals
    json = as_json only: [:start_date, :end_date],
                   include: {
                     user: { methods: [:formal_first_name, :formal_last_name] },
                     certification: { only: [:title, :description] },
                     organization: { only: [:name, :display_name, :description] }
                   }
    JSON.parse json.to_json, object_class: OpenStruct
  end

end
