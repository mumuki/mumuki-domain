require 'spec_helper'

describe Discussion, organization_workspace: :test do

  context 'when created' do
    let(:initiator) { create(:user) }
    let(:student) { create(:user) }
    let(:problem) { create(:indexed_exercise) }
    let(:discussion) { problem.discuss! initiator, title: 'Need help' }
    let(:moderator) { create(:user, permissions: {moderator: 'test/*'}) }

    it { expect(discussion.new_record?).to be false }
    it { expect(discussion.has_responses?).to be false }
    it { expect(discussion.has_validated_responses?).to be false }
    it { expect(discussion.messages).to eq [] }
    it { expect(discussion.initiator).to eq initiator }
    it { expect(discussion.title).to eq 'Need help' }
    it { expect(discussion.item).to eq problem }
    it { expect(initiator.subscribed_to? discussion).to be true }
    it { expect(discussion.status).to eq :opened }
    it { expect(discussion.reachable_statuses_for initiator).to eq [:closed] }
    it { expect(discussion.reachable_statuses_for moderator).to eq [:closed] }
    it { expect(discussion.reachable_statuses_for student).to eq [] }
    it { expect(discussion.commentable_by? student).to be true }
    it { expect(discussion.commentable_by? moderator).to be true }
    it { expect(discussion.requires_moderator_response).to be true }

    describe 'initiator sends a message' do
      before { discussion.submit_message!({content: 'I forgot to say this'}, initiator); discussion.reload }

      it { expect(discussion.has_responses?).to be false }
      it { expect(discussion.has_validated_responses?).to be false }
      it { expect(discussion.messages.first.content).to eq 'I forgot to say this' }
      it { expect(initiator.unread_discussions).to eq [] }
      it { expect(discussion.reachable_statuses_for initiator).to eq [:closed] }
      it { expect(discussion.reachable_statuses_for moderator).to eq [:closed] }
      it { expect(discussion.reachable_statuses_for student).to eq [] }
      it { expect(discussion.requires_moderator_response).to be true }

      describe 'and closes the discussion' do
        before { discussion.update_status!(:closed, initiator) }

        it { expect(discussion.status).to eq :closed }
        it { expect(discussion.reachable_statuses_for initiator).to eq [] }
        it { expect(discussion.reachable_statuses_for moderator).to eq [:opened, :solved] }
        it { expect(discussion.reachable_statuses_for student).to eq [] }
        it { expect(discussion.commentable_by? student).to be false }
        it { expect(discussion.commentable_by? moderator).to be true }
      end

      describe 'and submits a valid solution' do
        before { stub_runner! status: :passed, result: 'passed!' }
        before { problem.submit_solution!(initiator, content: 'x = 2') }
        before { discussion.reload }

        it { expect(discussion.status).to eq :closed }
        it { expect(discussion.reachable_statuses_for initiator).to eq [] }
        it { expect(discussion.reachable_statuses_for moderator).to eq [:opened, :solved] }
        it { expect(discussion.reachable_statuses_for student).to eq [] }
        it { expect(discussion.commentable_by? student).to be false }
        it { expect(discussion.commentable_by? moderator).to be true }
      end
    end

    describe 'receive message from another student' do
      before { discussion.submit_message!({content: 'You should do this'}, student); discussion.reload }

      it { expect(discussion.has_responses?).to be true }
      it { expect(discussion.has_validated_responses?).to be false }
      it { expect(initiator.unread_discussions).to include discussion }
      it { expect(discussion.messages.first.content).to eq 'You should do this' }
      it { expect(discussion.reachable_statuses_for initiator).to eq [:closed] }
      it { expect(discussion.reachable_statuses_for moderator).to eq [:closed, :solved] }
      it { expect(discussion.reachable_statuses_for student).to eq [] }
      it { expect(student.subscribed_to? discussion).to be true }
      it { expect(discussion.requires_moderator_response).to be true }

      describe 'gets updated to pending_review by initiator but it can not do it' do
        it { expect { discussion.update_status!(:pending_review, initiator) }.not_to change(discussion, :status) }
      end

      describe 'initiator tries to solve it' do
        it { expect { discussion.update_status!(:solved, initiator) }.not_to change(discussion, :status) }
      end

      describe 'gets solved by moderator' do
        before { discussion.update_status!(:solved, moderator) }

        it { expect(discussion.status).to eq :solved }
        it { expect(discussion.reachable_statuses_for initiator).to eq [] }
        it { expect(discussion.reachable_statuses_for moderator).to eq [:opened, :closed] }
        it { expect(discussion.reachable_statuses_for student).to eq [] }
        it { expect(discussion.commentable_by? student).to be false }
        it { expect(discussion.commentable_by? moderator).to be true }
      end

      describe 'and submits a valid solution' do
        before { stub_runner! status: :passed, result: 'passed!' }
        before { problem.submit_solution!(initiator, content: 'x = 2') }
        before { discussion.reload }

        it { expect(discussion.status).to eq :closed }
      end

      describe 'and that message gets approved' do
        before { discussion.messages.last.update! approved: true }
        before { discussion.reload }

        it { expect(discussion.has_validated_responses?).to be true }
        it { expect(discussion.requires_moderator_response).to be false }

        describe 'and submits a valid solution' do
          before { stub_runner! status: :passed, result: 'passed!' }
          before { problem.submit_solution!(initiator, content: 'x = 2') }
          before { discussion.reload }

          it { expect(discussion.status).to eq :pending_review }
        end
      end
    end

    describe 'receives message from a moderator' do
      before { discussion.submit_message!({content: 'I suggest doing this'}, moderator) }
      before { discussion.reload }

      it { expect(discussion.has_responses?).to be true }
      it { expect(discussion.has_validated_responses?).to be true }
      it { expect(initiator.unread_discussions).to include discussion }
      it { expect(discussion.messages.last.content).to eq 'I suggest doing this' }
      it { expect(discussion.reachable_statuses_for initiator).to eq [:pending_review] }
      it { expect(discussion.reachable_statuses_for moderator).to eq [:closed, :solved] }
      it { expect(discussion.reachable_statuses_for student).to eq [] }
      it { expect(moderator.subscribed_to? discussion).to be true }
      it { expect(discussion.requires_moderator_response).to be false }

      describe 'gets updated to pending_review by initiator' do
        before { discussion.update_status!(:pending_review, initiator) }

        it { expect(discussion.status).to eq :pending_review }
        it { expect(discussion.reachable_statuses_for initiator).to eq [] }
        it { expect(discussion.reachable_statuses_for moderator).to eq [:opened, :closed, :solved] }
        it { expect(discussion.reachable_statuses_for student).to eq [] }
        it { expect(discussion.commentable_by? student).to be false }
        it { expect(discussion.commentable_by? moderator).to be true }
      end

      describe 'and submits a valid solution' do
        before { stub_runner! status: :passed, result: 'passed!' }
        before { problem.submit_solution!(initiator, content: 'x = 2') }
        before { discussion.reload }

        it { expect(discussion.status).to eq :pending_review }
      end

      describe 'initiator tries to solve it' do
        it { expect { discussion.update_status!(:solved, initiator) }.not_to change(discussion, :status) }
      end

      describe 'gets solved by moderator' do
        before { discussion.update_status!(:solved, moderator) }

        it { expect(discussion.status).to eq :solved }
        it { expect(discussion.reachable_statuses_for initiator).to eq [] }
        it { expect(discussion.reachable_statuses_for moderator).to eq [:opened, :closed] }
        it { expect(discussion.reachable_statuses_for student).to eq [] }
        it { expect(discussion.commentable_by? student).to be false }
        it { expect(discussion.commentable_by? moderator).to be true }
      end
    end
  end

  describe '#toggle_subscription!' do
    let(:discussion) { create(:discussion, {organization: Organization.current}) }

    context 'when the student is not subscribed' do
      let(:student) { create(:user) }

      before { student.toggle_subscription!(discussion) }

      it { expect(student.subscribed_to? discussion).to be true }
    end

    context 'when the student is subscribed' do
      let(:student) { create(:user, watched_discussions: [discussion]) }

      before { student.toggle_subscription!(discussion) }

      it { expect(student.subscribed_to? discussion).to be false }
    end
  end

  describe '#toggle_upvote!' do
    let(:discussion) { create(:discussion, {organization: Organization.current}) }

    context 'when the student has not upvoted' do
      let(:student) { create(:user) }

      before { student.toggle_upvote!(discussion) }

      it { expect(student.upvoted? discussion).to be true }
      it { expect(discussion.reload.upvotes_count).to be 1 }
    end

    context 'when the student is subscribed' do
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

  describe 'scope for user' do
    let(:initiator) { create(:user) }
    let(:other_user) { create(:user) }
    let(:exercise) { create(:problem) }

    let!(:public_discussions) { [:opened, :solved].map { |it| exercise.discuss!(initiator, {status: it, title: 'A disc'}) } }
    let!(:private_discussions) { [:pending_review, :closed].map { |it| exercise.discuss!(initiator, {status: it, title: 'A disc'}) } }
    let!(:other_discussion) { exercise.discuss!(other_user, {status: :closed, title: 'A disc'}) }

    context 'as student' do
      let(:student) { create(:user) }
      it { expect(exercise.discussions.for_user(student)).to match_array public_discussions }
    end

    context 'as initiator' do
      it { expect(exercise.discussions.for_user(initiator)).to match_array public_discussions + private_discussions }
    end

    context 'as moderator' do
      let(:moderator) { create(:user, permissions: {moderator: 'test/*'}) }
      it { expect(exercise.discussions.for_user(moderator)).to match_array public_discussions + private_discussions + [other_discussion] }
    end

    context 'for other item' do
      let(:other_exercise) { create(:exercise) }
      it { expect(other_exercise.discussions.for_user(initiator)).to be_empty }
    end
  end

  describe 'messages not being deleted' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:problem) { create(:indexed_exercise) }
    let(:assignment) { problem.submit_solution! user }
    let(:discussion) { problem.discuss!(user, {title: 'A discussion'}) }

    before { discussion.submit_message!({content: 'You should do this'}, user) }
    before { stub_runner! status: :passed, result: 'passed!' }
    before { problem.submit_solution! other_user }

    it { expect(discussion.messages.count).to eq 1 }
  end

  describe '#update_counters_cache!' do
    let(:initiator) { create(:user) }
    let(:other_user) { create(:user) }
    let(:problem) { create(:problem) }
    let(:moderator) { create(:user, permissions: {moderator: 'test/*'}) }
    let(:assignment) { problem.submit_solution! initiator }
    let(:discussion) { problem.discuss!(initiator, {title: 'A discussion'}) }

    context 'when discussion is created' do
      it { expect(discussion.requires_moderator_response?).to be true }
      it { expect(discussion.validated_messages_count).to eq 0 }
      it { expect(discussion.messages_count).to eq 0 }
    end

    context 'when moderator responds' do
      before { discussion.submit_message!({content: 'it is ok'}, moderator) }

      it { expect(discussion.reload.requires_moderator_response?).to be false }
      it { expect(discussion.reload.validated_messages_count).to eq 1 }
      it { expect(discussion.reload.messages_count).to eq 1 }
    end

    context 'when moderator and other user responds' do
      before { discussion.submit_message!({content: 'it is ok'}, moderator) }
      before { discussion.submit_message!({content: 'same question'}, other_user) }

      it { expect(discussion.reload.requires_moderator_response?).to be false }
      it { expect(discussion.reload.validated_messages_count).to eq 1 }
      it { expect(discussion.reload.messages_count).to eq 2 }
    end

    context 'when moderator and initiator responds' do
      before { discussion.submit_message!({content: 'it is ok'}, moderator) }
      before { discussion.submit_message!({content: 'need more help'}, initiator) }
      before { discussion.submit_message!({content: 'same question'}, other_user) }

      it { expect(discussion.reload.requires_moderator_response?).to be true }
      it { expect(discussion.reload.validated_messages_count).to eq 1 }
      it { expect(discussion.reload.messages_count).to eq 3 }
    end

    context 'when moderator and initiator responds but the latter is not a question' do
      before { discussion.submit_message!({content: 'it is ok'}, moderator) }
      before { discussion.submit_message!({content: 'need more help'}, initiator) }
      before { discussion.messages.last.update! not_actually_a_question: true }
      before { discussion.submit_message!({content: 'same question'}, other_user) }

      it { expect(discussion.reload.requires_moderator_response?).to be false }
      it { expect(discussion.reload.validated_messages_count).to eq 1 }
      it { expect(discussion.reload.messages_count).to eq 3 }
    end

    context 'when moderator and initiator responds twice' do
      before { discussion.submit_message!({content: 'it is ok'}, moderator) }
      before { discussion.submit_message!({content: 'need more help'}, initiator) }
      before { discussion.messages.last.update! not_actually_a_question: true }
      before { discussion.submit_message!({content: 'same question'}, initiator) }

      it { expect(discussion.reload.requires_moderator_response?).to be true }
      it { expect(discussion.reload.validated_messages_count).to eq 1 }
      it { expect(discussion.reload.messages_count).to eq 3 }
    end

    context 'when message gets deleted' do
      before { discussion.submit_message!({content: 'it is ok'}, moderator) }
      before { discussion.submit_message!({content: 'another question'}, initiator) }
      before { discussion.messages.last.destroy! }

      it { expect(discussion.reload.requires_moderator_response?).to be false }
      it { expect(discussion.reload.validated_messages_count).to eq 1 }
      it { expect(discussion.reload.messages_count).to eq 1 }
    end

    context 'long discussion' do
      before { discussion.submit_message!({content: 'it is ok'}, moderator) }
      before { discussion.submit_message!({content: 'need more help'}, initiator) }
      before { discussion.messages.last.update! not_actually_a_question: true }
      before { discussion.submit_message!({content: 'same question'}, initiator) }
      before { discussion.submit_message!({content: 'do it like this'}, moderator) }
      before { discussion.submit_message!({content: 'thanks'}, initiator) }
      before { discussion.messages.last.update! not_actually_a_question: true }

      it { expect(discussion.reload.requires_moderator_response?).to be false }
      it { expect(discussion.reload.validated_messages_count).to eq 2 }
      it { expect(discussion.reload.messages_count).to eq 5 }
    end
  end
end
