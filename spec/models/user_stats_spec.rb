require 'spec_helper'

describe UserStats, organization_workspace: :test do
  let(:user) { create(:user) }
  let(:stats) { UserStats.stats_for user }

  describe '#activity' do
    let(:activity) { stats.activity }
    let(:another_user) { create(:user) }

    context 'exercises' do
      let(:book) { Organization.current.book }
      let(:exercises) { create_list(:exercise, 4) }

      let!(:chapter) do
        create(:chapter,
               book: book,
               lessons: [
                   create(:lesson, exercises: exercises.take(2) ),
                   create(:lesson, exercises: exercises.drop(2) )])
      end

      before { reindex_current_organization! }

      before do
        exercises[0].submit_solution!(user, content: '').passed!
        exercises[0].submit_solution!(user, content: '').failed!

        assignment = exercises[1].submit_solution!(user, content: '')
        assignment.update!(submitted_at: 2.days.until, status: 'skipped')

        exercises[0].submit_solution!(another_user, content: '').passed!
      end

      context 'without date filter' do
        it { expect(stats.activity[:exercises]).to eq(solved_count: 2, count: 4) }
      end

      context 'with date filter' do
        it { expect(stats.activity(3.days.until..1.day.until)[:exercises]).to eq(solved_count: 1, count: 4) }
      end

      context 'when book changes' do
        let(:other_book) { create(:book_with_full_tree, exercises: exercises[1..2]) }

        before do
          Organization.current.update! book: other_book
          reindex_current_organization!
        end

        it { expect(stats.activity[:exercises]).to eq(solved_count: 1, count: 2) }
      end

      context 'for other organization with same book' do
        let(:other_orga) { create(:organization, book: book) }

        before do
          other_orga.switch!
          reindex_current_organization!
        end

        it { expect(stats.activity[:exercises]).to eq(solved_count: 0, count: 4) }

      end

      context 'for organization with complements' do
        let!(:complement) { create(:complement, exercises: [create(:exercise), create(:exercise)]) }
        before { reindex_current_organization! }

        it { expect(stats.activity[:exercises]).to eq(solved_count: 2, count: 4) }
      end

      context 'for organization with exams' do
        let!(:exam) { create(:exam, exercises: [create(:exercise), create(:exercise)]) }

        it { expect(stats.activity[:exercises]).to eq(solved_count: 2, count: 4) }
      end
    end

    context 'messages' do
      let(:problem) { create(:indexed_exercise) }
      let(:discussion) { problem.discuss! user, title: 'Need help' }

      before { discussion.submit_message!({content: 'Same issue here'}, another_user) }
      before { discussion.submit_message!({content: 'I forgot to say this', created_at: 2.days.until}, user) }
      before { discussion.submit_message!({content: 'Oh, this is the answer!', approved: true}, user) }

      context 'without date filter' do
        it { expect(stats.activity[:messages]).to eq(count: 2, approved: 1) }
      end

      context 'with date filter' do
        it { expect(stats.activity(3.day.until..1.day.until)[:messages]).to eq(count: 1, approved: 0) }
      end
    end
  end
end
