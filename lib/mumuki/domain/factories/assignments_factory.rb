FactoryBot.define do
  factory :assignment do
    status { :pending }
    exercise
    submitter { create(:user) }
    organization { Organization.current }
  end
end
