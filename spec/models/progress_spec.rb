require 'spec_helper'

describe Progress do
  let(:user) { create :user }

  # Organizations. Same content for each one
  let!(:orga1) { create :organization, name: 'orga-1', book: book }
  let!(:orga2) { create :organization, name: 'orga-2', book: book }

  # Empty book to test content validation on destination
  let(:empty_book) { create :book }

  # Main content tree
  #     B
  #     |
  #     T
  #   /  \
  #  G1   G2
  # |  \    \
  # E1  E2  E3
  let(:book) { create :book, name: 'book-1', chapters: [create(:chapter, topic: topic)] }

  let(:topic) { create :topic, name: 'topic-1', lessons: [create(:lesson, guide: guide1), create(:lesson, guide: guide2)] }

  let(:guide1) { create :guide, name: 'guide-1', exercises: [exercise1, exercise2] }
  let(:guide2) { create :guide, name: 'guide-2', exercises: [exercise3] }

  let(:exercise1) { create :exercise, name: 'exercise-1' }
  let(:exercise2) { create :exercise, name: 'exercise-2' }
  let(:exercise3) { create :exercise, name: 'exercise-3' }

  before do
    user.make_student_of!(orga1.slug)
    user.make_student_of!(orga2.slug)
    user.save!
  end

  # Progress tree for orga1
  #     IB (0/1)
  #     |
  #     IT (1/2)
  #     |
  #    IG1 (2/2)
  #   /  \
  #  A1✔ A2✔

  before { orga1.switch! }
  let!(:assignment1) { exercise1.submit_solution!(user, content: 'foo').tap(&:passed!) }
  let!(:assignment2) { exercise2.submit_solution!(user, content: 'bar').tap(&:passed!) }

  # Progress tree for orga2
  #     IB (0/1)
  #     |
  #     IT (0/2)
  #     |
  #    IG2 (0/1)
  #     |
  #    A3 X

  before { orga2.switch! }
  let!(:assignment3) { exercise3.submit_solution!(user, content: 'baz').tap(&:failed!) }

  let!(:pre_transfer_orga1_progress) { jsonify(book.progress_for(user, orga1)) }
  let!(:pre_transfer_orga2_progress) { jsonify(book.progress_for(user, orga2)) }
  let(:post_transfer_orga1_progress) { jsonify(book.progress_for(user, orga1)) }
  let(:post_transfer_orga2_progress) { jsonify(book.progress_for(user, orga2)) }

  def jsonify(progress_item)
    case progress_item
    when Indicator
      {
        children: progress_item.send(:children).map { |it| jsonify(it) }.sort_by { |it| it[:name] },
        name: progress_item.content.name,
        organization: progress_item.organization.name,
        type: progress_item.content_type
      }
      else
      {
        name: progress_item.exercise.name,
        organization: progress_item.organization.name,
        solution: progress_item.solution,
        type: 'Assignment'
      }
    end
  end

  describe 'progress transfer' do
    context 'before transfer' do
      # orga1: G1, T, B
      # orga2: G2, T, B
      it { expect(Indicator.count).to eq 6 }
      it { expect(Assignment.count).to eq 3 }

      it { expect(pre_transfer_orga1_progress).to json_like({name: 'book-1',
                                                             organization: 'orga-1',
                                                             type: 'Book',
                                                             children: [{
                                                               name: 'topic-1',
                                                               organization: 'orga-1',
                                                               type: 'Topic',
                                                               children: [{
                                                                 name: 'guide-1',
                                                                 organization: 'orga-1',
                                                                 type: 'Guide',
                                                                 children: [
                                                                   { name: 'exercise-1', organization: 'orga-1', solution: 'foo', type: 'Assignment' },
                                                                   { name: 'exercise-2', organization: 'orga-1', solution: 'bar', type: 'Assignment' }
                                                                 ]}]}]}) }

      it { expect(pre_transfer_orga2_progress).to json_like({name: 'book-1',
                                                             organization: 'orga-2',
                                                             type: 'Book',
                                                             children: [{
                                                               name: 'topic-1',
                                                               organization: 'orga-2',
                                                               type: 'Topic',
                                                               children: [{
                                                                 name: 'guide-2',
                                                                 organization: 'orga-2',
                                                                 type: 'Guide',
                                                                 children: [
                                                                   { name: 'exercise-3', organization: 'orga-2', solution: 'baz', type: 'Assignment' }
                                                                 ]}]}]}) }
    end

    context 'it disallows transfer when content not in destination orga' do
      before { orga1.update! book: empty_book }

      it { expect { empty_book.progress_for(user, orga1).copy_to!(orga2) }.to raise_error "Transferred progress' content must be available in destination!" }
    end

    describe 'copy_to!' do
      context 'on copying assignment' do
        before { assignment1.copy_to!(orga2) }

        # orga1: G1, T, B
        # orga2: G1, G2, T, B
        pending { expect(Indicator.count).to eq 7 }
        pending { expect(Assignment.count).to eq 4 }

        pending { expect(post_transfer_orga1_progress).to json_like pre_transfer_orga1_progress }

        pending { expect(post_transfer_orga2_progress).to json_like({name: 'book-1',
                                                                organization: 'orga-2',
                                                                type: 'Book',
                                                                children: [
                                                                  {
                                                                    name: 'topic-1',
                                                                    organization: 'orga-2',
                                                                    type: 'Topic',
                                                                    children: [
                                                                      {
                                                                        name: 'guide-1',
                                                                        organization: 'orga-2',
                                                                        type: 'Guide',
                                                                        children: [
                                                                          { name: 'exercise-1', organization: 'orga-2', solution: 'foo', type: 'Assignment' }
                                                                        ]},
                                                                      {
                                                                        name: 'guide-2',
                                                                        organization: 'orga-2',
                                                                        type: 'Guide',
                                                                        children: [
                                                                          { name: 'exercise-3', organization: 'orga-2', solution: 'baz', type: 'Assignment' }
                                                                      ]}]}]}) }

        context 'before triggering indicator recalculation' do
          pending { expect(guide1.progress_for(user, orga2).dirty_by_submission).to be true }
          pending { expect(topic.progress_for(user, orga2).dirty_by_submission).to be true }
          pending { expect(book.progress_for(user, orga2).dirty_by_submission).to be true }
        end

        context 'after triggering indicator recalculation' do
          before { book.progress_for(user, orga2).completed? }

          pending { expect(book.progress_for(user, orga2).completed?).to be false }
          pending { expect(guide1.progress_for(user, orga2).dirty_by_submission).to be false }
          pending { expect(guide1.progress_for(user, orga2).send(:children_passed_count)).to be 1 }
          pending { expect(topic.progress_for(user, orga2).dirty_by_submission).to be false }
          pending { expect(topic.progress_for(user, orga2).send(:children_passed_count)).to be 0 }
          pending { expect(book.progress_for(user, orga2).dirty_by_submission).to be false }
          pending { expect(book.progress_for(user, orga2).send(:children_passed_count)).to be 0 }
        end
      end

      context 'on copying guide' do
        before { guide1.progress_for(user, orga1).copy_to!(orga2) }

        # orga1: G1, T, B
        # orga2: G1, G2, T, B
        it { expect(Indicator.count).to eq 7 }
        it { expect(Assignment.count).to eq 5 }

        it { expect(post_transfer_orga1_progress).to json_like pre_transfer_orga1_progress }

        it { expect(post_transfer_orga2_progress).to json_like({name: 'book-1',
                                                                organization: 'orga-2',
                                                                type: 'Book',
                                                                children: [
                                                                  {
                                                                    name: 'topic-1',
                                                                    organization: 'orga-2',
                                                                    type: 'Topic',
                                                                    children: [
                                                                      {
                                                                        name: 'guide-1',
                                                                        organization: 'orga-2',
                                                                        type: 'Guide',
                                                                        children: [
                                                                          { name: 'exercise-1', organization: 'orga-2', solution: 'foo', type: 'Assignment' },
                                                                          { name: 'exercise-2', organization: 'orga-2', solution: 'bar', type: 'Assignment' }
                                                                        ]},
                                                                      {
                                                                        name: 'guide-2',
                                                                        organization: 'orga-2',
                                                                        type: 'Guide',
                                                                        children: [
                                                                          { name: 'exercise-3', organization: 'orga-2', solution: 'baz', type: 'Assignment' }
                                                                        ]}]}]}) }
        context 'before triggering indicator recalculation' do
          it { expect(guide1.progress_for(user, orga2).dirty_by_submission).to be true }
          it { expect(topic.progress_for(user, orga2).dirty_by_submission).to be true }
          it { expect(book.progress_for(user, orga2).dirty_by_submission).to be true }
        end

        context 'after triggering indicator recalculation' do
          before { book.progress_for(user, orga2).completed? }

          it { expect(book.progress_for(user, orga2).completed?).to be false }
          it { expect(guide1.progress_for(user, orga2).dirty_by_submission).to be false }
          it { expect(guide1.progress_for(user, orga2).send(:children_passed_count)).to be 2 }
          it { expect(topic.progress_for(user, orga2).dirty_by_submission).to be false }
          it { expect(topic.progress_for(user, orga2).send(:children_passed_count)).to be 1 }
          it { expect(book.progress_for(user, orga2).dirty_by_submission).to be false }
          it { expect(book.progress_for(user, orga2).send(:children_passed_count)).to be 0 }
        end
      end

      context 'on copying topic' do
        let!(:guide2_indicator) { guide2.progress_for(user, orga2) }
        before { topic.progress_for(user, orga1).copy_to!(orga2) }

        # orga1: G1, T, B
        # orga2: G1, T, B
        pending { expect(Indicator.count).to eq 6 }
        pending { expect(Assignment.count).to eq 4 }

        pending { expect { guide2_indicator.reload }.to raise_error(ActiveRecord::RecordNotFound) }

        pending { expect(post_transfer_orga1_progress).to json_like pre_transfer_orga1_progress }

        pending { expect(post_transfer_orga2_progress).to json_like({name: 'book-1',
                                                                organization: 'orga-2',
                                                                type: 'Book',
                                                                children: [
                                                                  {
                                                                    name: 'topic-1',
                                                                    organization: 'orga-2',
                                                                    type: 'Topic',
                                                                    children: [
                                                                      {
                                                                        name: 'guide-1',
                                                                        organization: 'orga-2',
                                                                        type: 'Guide',
                                                                        children: [
                                                                          { name: 'exercise-1', organization: 'orga-2', solution: 'foo', type: 'Assignment' },
                                                                          { name: 'exercise-2', organization: 'orga-2', solution: 'bar', type: 'Assignment' }
                                                                        ]}]}]}) }
      end
    end

    describe 'move_to!' do
      context 'on moving assignment' do
        before { assignment1.move_to!(orga2) }

        pending { expect(Indicator.count).to eq 7 }
        pending { expect(Assignment.count).to eq 3 }

        pending { expect(post_transfer_orga1_progress).to json_like({name: 'book-1',
                                                               organization: 'orga-1',
                                                               type: 'Book',
                                                               children: [{
                                                                            name: 'topic-1',
                                                                            organization: 'orga-1',
                                                                            type: 'Topic',
                                                                            children: [{
                                                                                         name: 'guide-1',
                                                                                         organization: 'orga-1',
                                                                                         type: 'Guide',
                                                                                         children: [
                                                                                           { name: 'exercise-2', organization: 'orga-1', solution: 'bar', type: 'Assignment' }
                                                                                         ]}]}]}) }

        pending { expect(post_transfer_orga2_progress).to json_like({name: 'book-1',
                                                                organization: 'orga-2',
                                                                type: 'Book',
                                                                children: [
                                                                  {
                                                                    name: 'topic-1',
                                                                    organization: 'orga-2',
                                                                    type: 'Topic',
                                                                    children: [
                                                                      {
                                                                        name: 'guide-1',
                                                                        organization: 'orga-2',
                                                                        type: 'Guide',
                                                                        children: [
                                                                          { name: 'exercise-1', organization: 'orga-2', solution: 'foo', type: 'Assignment' }
                                                                        ]},
                                                                      {
                                                                        name: 'guide-2',
                                                                        organization: 'orga-2',
                                                                        type: 'Guide',
                                                                        children: [
                                                                          { name: 'exercise-3', organization: 'orga-2', solution: 'baz', type: 'Assignment' }
                                                                        ]}]}]}) }
      end

      context 'on moving guide' do
        before { guide1.progress_for(user, orga1).move_to!(orga2) }

        it { expect(Indicator.count).to eq 6 }
        it { expect(Assignment.count).to eq 3 }

        it { expect(post_transfer_orga1_progress).to json_like({name: 'book-1',
                                                                organization: 'orga-1',
                                                                type: 'Book',
                                                                children: [{
                                                                             name: 'topic-1',
                                                                             organization: 'orga-1',
                                                                             type: 'Topic',
                                                                             children: []}]}) }

        it { expect(post_transfer_orga2_progress).to json_like({name: 'book-1',
                                                                organization: 'orga-2',
                                                                type: 'Book',
                                                                children: [
                                                                  {
                                                                    name: 'topic-1',
                                                                    organization: 'orga-2',
                                                                    type: 'Topic',
                                                                    children: [
                                                                      {
                                                                        name: 'guide-1',
                                                                        organization: 'orga-2',
                                                                        type: 'Guide',
                                                                        children: [
                                                                          { name: 'exercise-1', organization: 'orga-2', solution: 'foo', type: 'Assignment' },
                                                                          { name: 'exercise-2', organization: 'orga-2', solution: 'bar', type: 'Assignment' }
                                                                        ]},
                                                                      {
                                                                        name: 'guide-2',
                                                                        organization: 'orga-2',
                                                                        type: 'Guide',
                                                                        children: [
                                                                          { name: 'exercise-3', organization: 'orga-2', solution: 'baz', type: 'Assignment' }
                                                                        ]}]}]}) }
      end

      context 'on moving topic' do
        let!(:guide2_indicator) { guide2.progress_for(user, orga2) }
        before { topic.progress_for(user, orga1).move_to!(orga2) }

        pending { expect(Indicator.count).to eq 4 }
        pending { expect(Assignment.count).to eq 2 }

        pending { expect { guide2_indicator.reload }.to raise_error(ActiveRecord::RecordNotFound) }

        pending { expect(post_transfer_orga1_progress).to json_like({name: 'book-1',
                                                                organization: 'orga-1',
                                                                type: 'Book',
                                                                children: []}) }

        pending { expect(post_transfer_orga2_progress).to json_like({name: 'book-1',
                                                                organization: 'orga-2',
                                                                type: 'Book',
                                                                children: [
                                                                  {
                                                                    name: 'topic-1',
                                                                    organization: 'orga-2',
                                                                    type: 'Topic',
                                                                    children: [
                                                                      {
                                                                        name: 'guide-1',
                                                                        organization: 'orga-2',
                                                                        type: 'Guide',
                                                                        children: [
                                                                          { name: 'exercise-1', organization: 'orga-2', solution: 'foo', type: 'Assignment' },
                                                                          { name: 'exercise-2', organization: 'orga-2', solution: 'bar', type: 'Assignment' }
                                                                        ]}]}]}) }
      end
    end
  end
end
