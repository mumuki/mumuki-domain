FactoryBot.define do
  factory :certificate do
    started_at { 1.month.ago }
    ended_at { 1.minute.ago }
    user { build :user, first_name: 'Jane', last_name: 'Doe' }
    certificate_program { build :certificate_program }
  end
end
