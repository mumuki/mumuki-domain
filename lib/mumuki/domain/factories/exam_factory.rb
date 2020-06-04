FactoryBot.define do

  factory :exam, traits: [:guide_container] do
    duration { Faker::Number.between(from: 10, to:60).minutes }
    organization { Organization.current }
    course { create(:course, slug: 'test/foo') }
    start_time { 5.minutes.ago }
    end_time { 10.minutes.since }
    passing_criterion_type { 'none' }
  end
end
