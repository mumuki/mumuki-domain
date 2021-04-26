require 'spec_helper'

describe Message, organization_workspace: :test do
  describe '#parse_json' do
    let(:data) {
      {'exercise_id' => 1,
       'submission_id' => 'abcdef1',
       'message' => {
         'sender' => 'student@mumuki.org',
         'content' => 'a',
         'created_at' => '1/1/1'}} }

    let(:expected_json) {
      {'submission_id' => 'abcdef1',
       'content' => 'a',
       'created_at' => '1/1/1',
       'sender' => 'student@mumuki.org'} }

    let(:parsed_comment) { Message.parse_json(data) }

    it { expect(parsed_comment).to eq(expected_json) }
  end

  describe '.import_from_resource_h!' do
    let(:user) { create(:user) }
    let(:problem) { create(:problem) }

    context 'when last submission' do
      let!(:assignment) { problem.submit_solution! user, content: '' }
      let(:final_assignment) { Assignment.first }
      let(:message) { Message.first }
      let(:other_organization) { create(:organization) }

      let!(:data) {
        {'exercise_id' => problem.id,
         'submission_id' => assignment.submission_id,
         'organization' => Organization.current.name,
         'message' => {
           'sender' => 'teacher@mumuki.org',
           'content' => 'a',
           'created_at' => '1/1/1'}} }

      before { Message.import_from_resource_h! data }
      before do
        assignment = problem.submit_solution! user, content: ''
        Message.import_from_resource_h! 'exercise_id' => problem.id,
                                  'submission_id' => assignment.submission_id,
                                  'organization' => Organization.current.name,
                                  'message' => {
                                    'sender' => 'teacher@mumuki.org',
                                    'content' => 'a',
                                    'created_at' => '1/1/1'}
      end

      it { expect(Message.count).to eq 1 }
      it { expect(message.assignment).to_not be_nil }
      it { expect(message.assignment).to eq final_assignment }
      it { expect(message.to_resource_h.except 'created_at', 'updated_at', 'date')
             .to json_like submission_id: message.submission_id,
                           content: 'a',
                           sender: 'teacher@mumuki.org',
                           read: false,
                           exercise: {bibliotheca_id: problem.bibliotheca_id},
                           organization: 'test' }
      it { expect(final_assignment.has_messages?).to be true }
      it { expect(user.messages.count).to eq 1 }
      it { expect(user.messages_in_organization.count).to eq 1 }
      it { expect(user.messages_in_organization(other_organization).count).to eq 0 }
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
    end

  end
end
