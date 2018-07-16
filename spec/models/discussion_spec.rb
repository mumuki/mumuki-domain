require 'spec_helper'

describe Discussion, organization_workspace: :test do

  context 'when created' do
    let(:initiator) { create(:user) }
    let(:student) { create(:user) }
    let(:problem) { create(:problem) }
    let(:discussion) { problem.create_discussion! initiator, title: 'Need help' }
    let(:moderator) { create(:user, permissions: {moderator: 'private/*'}) }

    it { expect(discussion.new_record?).to be false }
    it { expect(discussion.has_responses?).to be false }
    it { expect(discussion.messages).to eq [] }
    it { expect(discussion.initiator).to eq initiator }
    it { expect(discussion.title).to eq 'Need help' }
    it { expect(discussion.item).to eq problem }
    it { expect(initiator.subscribed_to? discussion).to be true }
    it { expect(discussion.status).to eq :opened }
    it { expect(discussion.reachable_statuses_for initiator).to eq [:closed] }
    it { expect(discussion.reachable_statuses_for moderator).to eq [:closed, :solved] }
    it { expect(discussion.reachable_statuses_for student).to eq [] }

    describe 'initiator sends a message' do
      before { discussion.submit_message!({content: 'I forgot to say this'}, initiator)  }

      it { expect(discussion.has_responses?).to be false }
      it { expect(discussion.messages.first.content).to eq 'I forgot to say this' }
      it { expect(initiator.unread_discussions).to eq [] }
      it { expect(discussion.reachable_statuses_for initiator).to eq [:closed] }
      it { expect(discussion.reachable_statuses_for moderator).to eq [:closed, :solved] }
      it { expect(discussion.reachable_statuses_for student).to eq [] }

      describe 'and closes the discussion' do
        before { discussion.update_status!(:closed, initiator) }

        it { expect(discussion.status).to eq :closed }
        it { expect(discussion.reachable_statuses_for initiator).to eq [] }
        it { expect(discussion.reachable_statuses_for moderator).to eq [:opened, :solved] }
        it { expect(discussion.reachable_statuses_for student).to eq [] }
      end
    end

    describe 'receive message from helper' do
      before { discussion.submit_message!({content: 'You should do this'}, student)  }

      it { expect(discussion.has_responses?).to be true }
      it { expect(initiator.unread_discussions).to include discussion }
      it { expect(discussion.messages.first.content).to eq 'You should do this' }
      it { expect(discussion.reachable_statuses_for initiator).to eq [:pending_review] }
      it { expect(discussion.reachable_statuses_for moderator).to eq [:closed, :solved] }
      it { expect(discussion.reachable_statuses_for student).to eq [] }

      describe 'gets updated to pending_review by initiator' do
        before { discussion.update_status!(:pending_review, initiator) }

        it { expect(discussion.status).to eq :pending_review }
        it { expect(discussion.reachable_statuses_for initiator).to eq [] }
        it { expect(discussion.reachable_statuses_for moderator).to eq [:closed, :solved] }
        it { expect(discussion.reachable_statuses_for student).to eq [] }
      end

      describe 'initiator tries to solve it' do
        it { expect { discussion.update_status!(:solved, initiator) }.not_to change(discussion, :status) }
      end

      describe 'gets solved by moderator' do
        before { discussion.update_status!(:solved, moderator) }

        it { expect(discussion.status).to eq :solved }
        it { expect(discussion.reachable_statuses_for initiator).to eq [] }
        it { expect(discussion.reachable_statuses_for moderator).to eq [:closed] }
        it { expect(discussion.reachable_statuses_for student).to eq [] }
      end
    end
  end

  describe '#toggle_subscription!' do
    context 'when the student is not subscribed' do
      let(:discussion) { create(:discussion) }
      let(:student) { create(:user) }

      before { student.toggle_subscription!(discussion) }

      it { expect(student.subscribed_to? discussion).to be true }
    end

    context 'when the student is subscribed' do
      let(:discussion) { create(:discussion) }
      let(:student) { create(:user, watched_discussions: [discussion]) }

      before { student.toggle_subscription!(discussion) }

      it { expect(student.subscribed_to? discussion).to be false }
    end
  end

  describe '#toggle_upvote!' do
    context 'when the student has not upvoted' do
      let(:discussion) { create(:discussion) }
      let(:student) { create(:user) }

      before { student.toggle_upvote!(discussion) }

      it { expect(student.upvoted? discussion).to be true }
      it { expect(discussion.reload.upvotes_count).to be 1 }
    end

    context 'when the student is subscribed' do
      let(:discussion) { create(:discussion) }
      let(:student) { create(:user, upvoted_discussions: [discussion]) }

      before { student.toggle_upvote!(discussion) }

      it { expect(student.upvoted? discussion).to be false }
      it { expect(discussion.reload.upvotes_count).to be 0 }
    end
  end

  describe '#debatable_for' do
    let(:exercise) { create(:problem) }

    it { expect(described_class.debatable_for('Exercise', {exercise_id: exercise.id})).to eq exercise }
  end
end
