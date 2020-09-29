require 'spec_helper'

describe Awardee do
  let(:user) { create(:user) }
  let(:guide_medal) { create(:medal) }
  let(:another_guide_medal) { create(:medal) }
  let(:topic_medal) { create(:medal) }
  let(:book_medal) { create(:medal) }

  let(:organization) { create :organization, book: book }
  let(:book) { create :book, medal: book_medal, chapters: [chapter] }
  let(:chapter) { create :chapter, topic: topic }
  let(:topic) { create :topic, medal: topic_medal, lessons: [lesson, another_lesson] }
  let(:lesson) { create :lesson, guide: guide }
  let(:another_lesson) { create :lesson, guide: another_guide }
  let(:guide) { create :guide, medal: guide_medal, exercises: [
      create(:exercise, name: '1'),
      create(:exercise, name: '2'),
      create(:exercise, name: '3')
  ] }
  let(:another_guide) { create :guide, medal: another_guide_medal, exercises: [
      create(:exercise, name: '4')
  ] }

  before { organization.reindex_usages!.switch! }

  context 'acquired medals' do
    describe 'when a guide has been partially solved' do
      before { guide.exercises.first.submit_solution!(user, content: ':)').tap(&:passed!) }

      it { expect(user.acquired_medals).to be_empty }
      it { expect(user.unacquired_medals.size).to eq 4 }
      it { expect(user.unacquired_medals).to include guide_medal }
      it { expect(user.unacquired_medals).to include another_guide_medal }
      it { expect(user.unacquired_medals).to include topic_medal }
      it { expect(user.unacquired_medals).to include book_medal }
    end

    describe 'when a guide has been completely solved' do
      before { guide.exercises.each { |e| e.submit_solution!(user, content: ':)').tap(&:passed!) } }

      it { expect(user.acquired_medals).to eq [guide_medal] }
      it { expect(user.unacquired_medals.size).to eq 3 }
      it { expect(user.unacquired_medals).to include another_guide_medal }
      it { expect(user.unacquired_medals).to include topic_medal }
      it { expect(user.unacquired_medals).to include book_medal }
    end

    describe 'when all content has been completely solved' do
      before do
        guide.exercises.each { |e| e.submit_solution!(user, content: ':)').tap(&:passed!) }
        another_guide.exercises.each { |e| e.submit_solution!(user, content: ':)').tap(&:passed!) }
      end

      it { expect(user.acquired_medals.size).to eq 4 }
      it { expect(user.acquired_medals).to include guide_medal }
      it { expect(user.acquired_medals).to include another_guide_medal }
      it { expect(user.acquired_medals).to include topic_medal }
      it { expect(user.acquired_medals).to include book_medal }
      it { expect(user.unacquired_medals).to be_empty }
    end
  end
end
