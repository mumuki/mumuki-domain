require 'spec_helper'

describe Indicator, organization_workspace: :test do
  let(:user) { create(:user) }

  let(:exercise) { create :exercise, guide: guide }
  let(:sibling_exercise) { create :exercise, guide: sibling_guide }
  let(:guide) { create :indexed_guide }
  let(:topic) { guide.chapter.topic }
  let(:book) { guide.chapter.book }
  let!(:sibling_lesson) { create :lesson, topic: topic }
  let(:sibling_guide) { sibling_lesson.guide }

  let(:guide_indicator) { Indicator.find_by user: user, content: guide }
  let(:sibling_guide_indicator) { Indicator.find_by user: user, content: sibling_guide }
  let(:topic_indicator) { Indicator.find_by user: user, content: topic }
  let(:book_indicator) { Indicator.find_by user: user, content: book }

  before { reindex_current_organization! }

  let!(:assignment) { exercise.submit_solution!(user, content: 'foo').tap(&:passed!) }

  context 'on submission' do
    context 'tree is created when submission is sent' do
      it { expect(Assignment.count).to eq 1 }
      it { expect(Indicator.count).to eq 3 }
      it { expect(assignment.parent).to eq guide_indicator }
      it { expect(guide_indicator.parent).to eq topic_indicator }
      it { expect(topic_indicator.parent).to eq book_indicator }
      it { expect(book_indicator.parent).to be_nil }
    end

    context 'dirtiness' do
      let!(:sibling_assignment) { sibling_exercise.submit_solution!(user, content: 'foo').tap(&:passed!) }

      context 'indicator rebuild is not propagated up' do
        before { guide_indicator.rebuild! }

        it { expect(guide_indicator).to_not be_dirty_by_submission }
        it { expect(topic_indicator).to be_dirty_by_submission }
        it { expect(book_indicator).to be_dirty_by_submission }
      end

      context 'when indicators are not dirty' do
        before { Indicator.update_all dirty_by_content_change: false, dirty_by_submission: false }
        before { assignment.reload }

        context 'it is dirtied when submission changes completion status' do
          before { assignment.errored!('something went wrong!') }

          it { expect(guide_indicator).to be_dirty_by_submission }

          context 'dirtiness is propagated upwards' do
            it { expect(topic_indicator).to be_dirty_by_submission }
            it { expect(book_indicator).to be_dirty_by_submission }

            it { expect(sibling_guide_indicator).to_not be_dirty_by_submission }
          end
        end

        context 'it is not dirtied when submission does not change completion status' do
          before { assignment.reload }
          before { assignment.passed! }

          it { expect(guide_indicator).to_not be_dirty_by_submission }
        end
      end
    end
  end

  context 'on content change' do
    context 'when children do not change' do
      before { guide.import_from_resource_h!(guide.to_resource_h.merge description: 'foo') }

      it { expect(guide_indicator).to_not be_dirty_by_content_change }
    end

    context 'when children change' do
      let(:new_exercise_h) { build(:exercise).to_resource_h }

      before { guide.import_from_resource_h!(guide.to_resource_h.merge exercises: [new_exercise_h]) }

      it { expect(guide_indicator).to be_dirty_by_content_change }

      context 'dirtiness is not propagated up' do
        it { expect(topic_indicator).to_not be_dirty_by_content_change }
        it { expect(book_indicator).to_not be_dirty_by_content_change }
      end

      context 'indicator rebuild is propagated up' do
        before { guide_indicator.completed? }

        it { expect(guide_indicator).to_not be_dirty_by_content_change }
        it { expect(topic_indicator).to_not be_dirty_by_content_change }
        it { expect(book_indicator).to_not be_dirty_by_content_change }
        it { expect(topic_indicator).to_not be_dirty_by_submission }
        it { expect(book_indicator).to_not be_dirty_by_submission }
      end
    end

    context 'past children should not affect new progress tree' do
      before { topic_indicator.send :children_count }
      before { topic.import_from_resource_h!(topic.to_resource_h.merge lessons: []) }

      it { expect(topic_indicator.reload.send :children_count).to eq 0 }
      it { expect(topic_indicator.reload.send :children_passed_count).to eq 0 }
    end
  end

  context 'completion' do
    describe 'content is completed' do
      it { expect(guide_indicator).to be_completed }
    end

    describe 'content is not completed if failed afterwards' do
      before do
        assignment.failed!
        guide_indicator.reload.rebuild!
      end

      it { expect(guide_indicator).to_not be_completed }
    end
  end
end
