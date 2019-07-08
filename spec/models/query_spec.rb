require 'spec_helper'

describe Mumuki::Domain::Submission::Query do
  let!(:exercise) { create(:exercise) }
  let(:user) { create(:user) }

  before do
    expect_any_instance_of(Challenge).to receive(:automated_evaluation_class).and_return(Mumuki::Domain::Evaluation::Automated)
    allow_any_instance_of(Language).to receive(:run_query!).and_return(status: :passed, result: '5')
  end

  describe '#submit_query!', organization_workspace: :test do
    let!(:results) { exercise.submit_query!(user, query: 'foo', content: 'bar', cookie: ['foo', 'bar']) }
    let(:assignment) { exercise.find_assignment_for user }

    it { expect(results[:status]).to eq :passed }
    it { expect(results[:result]).to eq '5' }
    it { expect(assignment.solution).to eq 'bar' }
    it { expect(assignment.status).to eq :pending }
  end
end
