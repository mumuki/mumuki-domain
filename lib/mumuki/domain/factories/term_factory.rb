FactoryBot.define do
  factory :term do
    content { Faker::Lorem.sentence(word_count: 2000) }
    header { Faker::Lorem.sentence(word_count: 5) }
  end
end

