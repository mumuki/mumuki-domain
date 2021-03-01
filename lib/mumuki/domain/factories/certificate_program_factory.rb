FactoryBot.define do
  factory :certificate_program do
    title { 'Test' }
    description { 'Certificate program to test' }
    organization { Organization.current }
  end
end
