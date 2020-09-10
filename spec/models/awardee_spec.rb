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

  context 'obtained medals' do
    describe 'when a guide has been partially solved' do
      before { guide.exercises.first.submit_solution!(user, content: ':)').tap(&:passed!) }

      it { expect(user.medals).to be_empty }
    end

    describe 'when a guide has been completely solved' do
      before { guide.exercises.each { |e| e.submit_solution!(user, content: ':)').tap(&:passed!) } }

      it { expect(user.medals).to eq [guide_medal] }
    end

    describe 'when all content has been completely solved' do
      before do
        guide.exercises.each { |e| e.submit_solution!(user, content: ':)').tap(&:passed!) }
        another_guide.exercises.each { |e| e.submit_solution!(user, content: ':)').tap(&:passed!) }
      end

      it 'awards guide, topic and book medals' do
        expect(user.medals.size).to eq 4
        expect(user.medals).to include guide_medal
        expect(user.medals).to include another_guide_medal
        expect(user.medals).to include topic_medal
        expect(user.medals).to include book_medal
      end
    end
  end
end
