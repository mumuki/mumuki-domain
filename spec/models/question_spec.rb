require 'spec_helper'

describe Mumuki::Domain::Submission::Query, organization_workspace: :test do
  let!(:exercise) { create(:problem) }
  let(:student) { create(:user) }

  describe '#submit_question!' do
    let(:assignment) { exercise.find_assignment_for(student, Organization.current) }

    context 'when just a question on an empty assignment is sent' do
      before { exercise.submit_question!(student, content: 'Please help!') }

      it { expect(assignment.status).to eq :pending }
      it { expect(assignment.result).to be nil }

      it { expect(assignment.solution).to be nil }
      it { expect(assignment.messages.count).to eq 1 }
      it { expect(assignment.submission_id).to be nil }
      it { expect(assignment.submitted_at).to be nil }
    end

    context 'when a question on a previous submission is sent' do
      before do
        assignment = exercise.submit_solution!(student, content: 'x = 1').reload
        assignment.failed!
        @original_submission_id = assignment.submission_id
        @original_submitted_at = assignment.submitted_at
      end

      before { exercise.submit_question!(student, content: 'Please help!') }

      it { expect(assignment.status).to eq :failed }
      it { expect(assignment.result).to eq 'noop result' }
      it { expect(assignment.solution).to eq 'x = 1' }
      it { expect(assignment.messages.count).to eq 1 }
      it { expect(assignment.submission_id).to eq @original_submission_id }
      it { expect(assignment.submitted_at).to eq @original_submitted_at }
    end
  end
end
