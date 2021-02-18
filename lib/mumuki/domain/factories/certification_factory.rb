FactoryBot.define do
  factory :certification do
    title { 'Test' }
    description { 'Certification to test' }
    organization { Organization.current }
  end
end
