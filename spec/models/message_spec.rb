require 'spec_helper'

describe Message, organization_workspace: :test do

  describe 'validations' do
    context 'when no context' do
      let(:message) { Message.new content: 'content', sender: 'sender@mumuki.org' }
      it { expect(message.contextualized?).to be false }
      it { expect(message.valid?).to be false }
    end

    context 'when improperly contextualized' do
      let(:message) do
        Message.new content: 'content',
                    sender: 'sender@mumuki.org',
                    discussion: create(:discussion),
                    assignment: create(:assignment)
      end

      it { expect(message.contextualized?).to be false }
      it { expect(message.valid?).to be false }
    end

    context 'when direct' do
      let(:message) do
        Message.new content: 'content',
                    sender: 'sender@mumuki.org',
                    assignment: create(:assignment)
      end

      it { expect(message.contextualized?).to be true }
      it { expect(message.valid?).to be true }
    end

    context 'when non-direct' do
      let(:message) do
        Message.new content: 'content',
                    sender: 'sender@mumuki.org',
                    discussion: create(:discussion)
      end
      it { expect(message.contextualized?).to be true }
      it { expect(message.valid?).to be true }
    end
  end

  describe 'visible' do
    context 'non-direct messages' do
      before do
        create_list(:message, 5, discussion: create(:discussion), sender: 'sender@mumuki.org', deletion_motive: motive)
      end

      context 'self-deleted' do
        let(:motive) { :self_deleted }
        it { expect(Message.visible.count).to eq 0 }
      end

      context 'non-self-deleted' do
        let(:motive) { :inappropriate_content }

        it { expect(Message.visible.count).to eq 5 }
      end
    end

    context 'direct messages' do
      before do
        create_list(:message, 5, assignment: create(:assignment), sender: 'sender@mumuki.org')
      end

      it { expect(Message.visible.count).to eq 0 }
    end
  end

  describe '.import_from_resource_h!' do
    let(:user) { create(:user) }
    let(:problem) { create(:problem) }

    context 'when last submission' do
      let!(:assignment) { problem.submit_solution! user, content: '' }
      let(:message) { Message.first }
      let(:other_organization) { create(:organization) }

      let!(:data) {
        {'exercise_id' => problem.id,
         'submission_id' => assignment.submission_id,
         'organization' => Organization.current.name,
         'message' => {
           'sender' => 'teacher@mumuki.org',
           'content' => 'first message',
           'created_at' => '1/1/1'}} }

      before { Message.import_from_resource_h! data }
      before do
        assignment = problem.submit_solution! user, content: ''
        Message.import_from_resource_h! 'exercise_id' => problem.id,
                                  'submission_id' => assignment.submission_id,
                                  'organization' => Organization.current.name,
                                  'message' => {
                                    'sender' => 'teacher@mumuki.org',
                                    'content' => 'second message',
                                    'created_at' => '1/1/1'}
      end

      it { expect(Message.count).to eq 2 }
      it { expect(message.assignment).to_not be_nil }
      it { expect(message.assignment).to eq assignment }
      it { expect(message.contextualization).to eq assignment }
      it { expect(message.to_resource_h.except 'created_at', 'updated_at', 'date')
             .to json_like submission_id: message.submission_id,
                           assignment_id: message.assignment_id,
                           content: 'first message',
                           sender: 'teacher@mumuki.org',
                           read: false,
                           exercise: {bibliotheca_id: problem.bibliotheca_id},
                           organization: 'test' }
      it { expect(assignment.has_messages?).to be true }

      it { expect(user.messages_in_organization.count).to eq 2 }
      it { expect(user.messages_in_organization(other_organization).count).to eq 0 }
      it { expect(user.messages_in_organization.map(&:content)).to eq ['second message', 'first message'] }
      it { expect(user.messages_in_organization.map(&:stale?)).to eq [false, true] }
      it { expect(user.messages_in_organization.map(&:direct?)).to eq [true, true] }
      it { expect(user.messages_in_organization.map(&:contextualized?)).to eq [true, true] }

    end

    context 'when not last submission' do
      let!(:assignment) { problem.submit_solution! user, content: '' }
      let!(:data) {
        {'exercise_id' => problem.id,
         'submission_id' => assignment.submission_id,
         'organization' => Organization.current.name,
         'message' => {
           'sender' => 'teacher@mumuki.org',
           'content' => 'a',
           'type' => 'success',
           'created_at' => '1/1/1'}} }

      before { problem.submit_solution! user, content: 'other solution' }
      before { Message.import_from_resource_h! data }

      it { expect(Message.count).to eq 0 }
      it { expect(Assignment.first.has_messages?).to be false }
      it { expect(user.messages_in_organization.count).to eq 0 }
    end
  end
end
