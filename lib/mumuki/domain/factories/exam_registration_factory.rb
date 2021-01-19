FactoryBot.define do
  factory :exam_registration do
    description { Faker::Lorem.sentence(word_count: 5) }
    organization { Organization.current }
    start_time { 5.minutes.ago }
    end_time { 10.minutes.since }
  end
end
