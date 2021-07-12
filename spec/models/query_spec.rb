require 'spec_helper'

describe Mumuki::Domain::Submission::Query do
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(Language).to receive(:run_query!).and_return(status: :passed, result: '5')
  end

  describe '#submit_query!', organization_workspace: :test do
    let!(:results) { exercise.submit_query!(user, query: 'foo', content: 'bar', cookie: ['foo', 'bar']) }
    let(:assignment) { exercise.find_assignment_for(user, Organization.current) }

    shared_examples_for 'a query submission' do
      it { expect(results[:status]).to eq :passed }
      it { expect(results[:result]).to eq '5' }
      it { expect(assignment.solution).to eq 'bar' }
      it { expect(assignment.status).to eq :pending }
    end

    context 'a playground exercise' do
      let(:exercise) { create(:playground) }

      it_behaves_like 'a query submission'
      it { expect(assignment.submission_id).to_not be nil }
      it { expect(assignment.submitted_at).to_not be nil }
    end

    context 'a problem problem' do
      let(:exercise) { create(:playground) }

      it_behaves_like 'a query submission'
      it { expect(assignment.submission_id).to be nil }
      it { expect(assignment.submitted_at).to be nil }
    end
  end
end
