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
    end

    context 'messages' do
      let(:problem) { create(:indexed_exercise) }
      let(:discussion) { problem.discuss! user, title: 'Need help' }

      before { discussion.submit_message!({content: 'Same issue here'}, another_user) }
      before { discussion.submit_message!({content: 'I forgot to say this', date: 2.days.until}, user) }
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
