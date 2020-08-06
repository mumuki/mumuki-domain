FactoryBot.define do

  factory :message do
    content { Faker::Lorem.sentence(word_count: 3) }
  end
end
