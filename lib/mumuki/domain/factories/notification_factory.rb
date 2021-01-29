FactoryBot.define do
  factory :notification do
    organization { Organization.current }
  end
end
