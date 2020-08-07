FactoryBot.define do
  factory :discussion do
    title { Faker::Lorem.sentence(word_count: 2) }
    description { Faker::Lorem.sentence(word_count: 5) }
    initiator { create(:user) }
    item { create(:exercise) }
    organization { Organization.current rescue nil }
  end
end
