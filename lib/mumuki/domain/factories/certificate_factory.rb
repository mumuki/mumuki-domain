FactoryBot.define do
  factory :certificate do
    start_date { 1.month.ago }
    end_date { 1.minute.ago }
    user { build :user, first_name: 'Jane', last_name: 'Doe' }
    certificate_program { build :certificate_program }
  end
end
