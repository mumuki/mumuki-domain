FactoryBot.define do
  factory :book do
    name { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.sentence(word_count: 30) }
    slug { "mumuki/mumuki-test-book-#{SecureRandom.uuid}" }
  end
end
