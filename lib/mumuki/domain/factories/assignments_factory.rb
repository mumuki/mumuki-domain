FactoryBot.define do
  factory :assignment do
    status { :pending }
    exercise
    submitter { create(:user) }
    organization { create(:test_organization) }
  end
end
