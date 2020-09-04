require 'spec_helper'

describe Awardee, organization_workspace: :test do
  let(:user) { create(:user) }
  let(:guide_medal) { create(:medal) }
  let(:guide) { create(:indexed_guide, medal: guide_medal, exercises: [
      create(:exercise, name: '1'),
      create(:exercise, name: '2'),
      create(:exercise, name: '3')]
  ) }

  context 'obtained medals' do
    describe 'when a guide has been partially solved' do
      before { guide.exercises.first.submit_solution!(user, content: ':)').tap(&:passed!) }

      it { expect(user.medals).to be_empty }
    end

    describe 'when a guide has been completely solved' do
      before { guide.exercises.each { |e| e.submit_solution!(user, content: ':)').tap(&:passed!) } }

      it { expect(user.medals).to eq [guide_medal] }
    end
  end
end
