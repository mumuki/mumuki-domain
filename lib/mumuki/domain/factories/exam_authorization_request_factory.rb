FactoryBot.define do
  factory :exam_authorization_request do
    organization { Organization.current }
  end
end
