require 'spec_helper'

describe Topic do
  describe 'transparent navigation api' do
    let!(:topic) { create(:topic, slug: 'foo/bar') }
    let(:params) { { organization: 'foo', repository: 'bar' } }

    it { expect(topic.transparent_id).to eq 'foo/bar' }
    it { expect(topic.transparent_params).to eq params }
    it { expect(Topic.find_transparently!(params)).to eq topic }
  end

  describe 'slug normalization' do
    let(:topic) { create(:topic, slug: 'fLbUlGaReLlI/MuMUkI-saMPle-gUIde') }

    it { expect(topic.slug).to eq('flbulgarelli/mumuki-sample-guide') }
  end

  describe '#import_from_resource_h!' do
    let!(:haskell) { create(:haskell) }
    let!(:gobstones) { create(:gobstones) }

    let!(:lesson_1) { create(:lesson, name: 'l1') }
    let(:guide_1) { lesson_1.guide }

    let!(:lesson_2) { create(:lesson, name: 'l2') }

    let!(:guide_2) { create(:guide, name: 'g2') }
    let!(:guide_3) { create(:guide, name: 'g3') }

    let(:topic_resource_h) do
      {name: 'sample topic',
       description: 'topic description',
       slug: 'mumuki/mumuki-sample-topic',
       locale: 'en',
       lessons: [guide_2, guide_1, guide_3].map(&:slug)}
    end

    context 'when guide is empty' do
      let(:topic) { create(:topic, lessons: [lesson_1, lesson_2]) }

      before do
        topic.import_from_resource_h!(topic_resource_h)
      end

      it { expect(topic.name).to eq 'sample topic' }
      it { expect(topic.description).to eq 'topic description' }
      it { expect(topic.locale).to eq 'en' }
      it { expect(topic.lessons.count).to eq 3 }
      it { expect(topic.lessons.first.guide).to eq guide_2 }
      it { expect(topic.lessons.second).to eq lesson_1 }
      it { expect(topic.lessons.third.guide).to eq guide_3 }
      it { expect(Guide.count).to eq 4 }
      it { expect(Lesson.count).to eq 3 }
    end
  end

  describe '#monolesson' do
    context 'topic has one lesson' do
      let(:topic) { create :topic, slug: 'foo/bar', lessons: [create(:lesson, name: 'l1')] }
      it { expect(topic.monolesson?).to eq true }
    end

    context 'topic has two lessons' do
      let(:topic) { create :topic, slug: 'foo/bar', lessons: [create(:lesson, name: 'l1'), create(:lesson, name: 'l2')] }
      it { expect(topic.monolesson?).to eq false }
    end

    context 'topic has no lessons' do
      let(:topic) { create :topic, slug: 'foo/bar', lessons: [] }
      it { expect(topic.monolesson?).to eq false }
    end
  end

  describe '#pending_lessons' do
    let(:book) { create :book, topics: [topic] }
    let(:topic) { create :topic, lessons: [lesson] }
    let(:lesson) { create :lesson, exercises: [create(:exercise, manual_evaluation: true)] }
    let(:user) { create :user }
    let(:pending_lessons_count) { topic.pending_lessons(user).to_a.count }

    before { organization.switch!.reindex_usages! }

    context 'on organization with prevent_manual_evaluation_content' do
      let(:organization) { create :organization, prevent_manual_evaluation_content: true, book: book }

      it { expect(pending_lessons_count).to eq 0 }
    end

    context 'on organization without prevent_manual_evaluation_content' do
      let(:organization) { create :organization, book: book }

      it { expect(pending_lessons_count).to eq 1 }
    end
  end
end
