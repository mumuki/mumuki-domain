require 'spec_helper'

describe Mumuki::Domain::Submission::Solution, organization_workspace: :test do

  let(:user) { create(:user) }

  describe '#try_submit_solution!' do

    context 'when on chapter' do
      let(:problem) { create(:problem) }
      let!(:chapter) {
        create(:chapter, name: 'Functional Programming', lessons: [
          create(:lesson, exercises: [problem])
        ]) }

      before { reindex_current_organization! }
      let!(:result) { problem.try_submit_solution! user }

      it { expect(result).to eq problem.find_assignment_for(user, Organization.current) }
      it { expect(result.attempts_left).to eq nil }
      it { expect(result.attempts_left?).to be true }
    end

    context 'when on exam' do
      let(:problem) { create(:problem) }
      let!(:exam) { create(:exam, max_problem_submissions: 10, exercises: [problem]) }

      before { reindex_current_organization! }
      let(:result) { problem.try_submit_solution! user }

      it { expect(result).to eq problem.find_assignment_for(user, Organization.current) }
      it { expect(result.attempts_left).to eq 9 }
      it { expect(result.attempts_left?).to be true }
    end
  end

  describe '#submit_solution!' do

    before { expect_any_instance_of(Challenge).to receive(:automated_evaluation_class).and_return(Mumuki::Domain::Evaluation::Automated) }
    before { expect_any_instance_of(Language).to receive(:run_tests!).with(bridge_request).and_return(bridge_response) }
    let(:submission_attributes) { {} }
    let(:assignment) { exercise.submit_solution! user, submission_attributes }

    context 'when results have no expectation' do
      let(:exercise) { create(:indexed_exercise) }
      let(:bridge_request) do
        {
          content: nil,
          custom_expectations: "\n",
          expectations: [],
          extra: "",
          locale: "en",
          settings: {},
          test: "dont care"
        }
      end
      let(:bridge_response) { {result: '0 failures', status: :passed} }

      it { expect(assignment.status).to eq(:passed) }
      it { expect(assignment.result).to include('0 failures') }
    end

    context 'when submissions has client result' do
      let(:exercise) { create(:indexed_exercise) }
      let(:bridge_request) do
        {
          content: 'x = 2',
          custom_expectations: "\n",
          expectations: [],
          extra: "",
          locale: "en",
          settings: {},
          test: "dont care",
          client_result: {
            status: :passed,
            test_results: [{title: 'true is true', status: :passed, result: ''}]
          }
        }
      end
      let(:bridge_response) { {result: '0 failures', status: :passed} }
      let(:submission_attributes) do
        {
          content: 'x = 2',
          client_result: {
            status: :passed,
            test_results: [{title: 'true is true', status: :passed, result: ''}]
          }
        }
      end

      it { expect(assignment.status).to eq(:passed) }
      it { expect(assignment.result).to include('0 failures') }
    end

    context 'when results have standard expectations' do
      let(:exercise) {
        create(:indexed_exercise, expectations: [{binding: :foo, inspection: :HasComposition}]) }
      let(:bridge_request) do
        {
          content: nil,
          custom_expectations: "\n",
          expectations: [{"binding"=>:foo, "inspection"=>:HasComposition}],
          extra: "",
          locale: "en",
          settings: {},
          test: "dont care"
        }
      end
      let(:bridge_response) { {
          result: '0 failures',
          status: :passed,
          expectation_results: [binding: 'foo', inspection: 'HasBinding', result: :passed]} }

      it { expect(assignment.status).to eq(:passed) }
      it { expect(assignment.result).to include('0 failures') }
      it { expect(assignment.expectation_results).to eq([{binding: 'foo', inspection: 'HasBinding', result: :passed}]) }
    end

    context 'when results have custom expectations' do
      let(:exercise) { create(:indexed_exercise, custom_expectations: 'expectation "foo uses composition": `foo` uses composition;') }
      let(:bridge_request) do
        {
          content: nil,
          custom_expectations: "expectation \"foo uses composition\": `foo` uses composition;\n",
          expectations: [],
          extra: "",
          locale: "en",
          settings: {},
          test: "dont care"
        }
      end
      let(:bridge_response) { {
          result: '0 failures',
          status: :passed,
          expectation_results: [binding: '<<custom>>', inspection: 'foo uses composition', result: :passed]} }

      it { expect(assignment.status).to eq(:passed) }
      it { expect(assignment.result).to include('0 failures') }
      it { expect(assignment.expectation_results).to eq([binding: '<<custom>>', inspection: 'foo uses composition', result: :passed]) }
    end
  end

  describe '#submit_solution!' do
    let(:organization)  { create :organization }
    let!(:organization2) { create :organization, name: 'orga2', book: organization.book }
    let(:user) { create :user }

    before { organization.switch! }
    let(:exercise) { create :indexed_exercise }
    let(:guide) { exercise.guide }
    let!(:assignment) { exercise.submit_solution!(user, content: 'foo') }

    context 'when old organization still has the exercise' do
      before do
        organization2.reindex_usages!
        organization2.switch!
        exercise.submit_solution!(user, content: 'bar')
        assignment.reload
      end

      it { expect(assignment.solution).to eq('bar') }
      it { expect(assignment.parent).to_not eq(guide.progress_for(user, organization )) }
      it { expect(assignment.parent).to     eq(guide.progress_for(user, organization2)) }
      it { expect(guide.progress_for(user, organization)).to be_dirty_by_submission }
    end

    context 'when old organization has not got the exercise' do
      let(:other_book) { create(:book) }
      before do
        organization2.reindex_usages!
        organization2.switch!
        organization.update! book: other_book
        organization.reindex_usages!

        exercise.submit_solution!(user, content: 'bar')
        assignment.reload
      end

      it { expect(assignment.solution).to eq('bar') }
      it { expect(assignment.parent).to_not eq(guide.progress_for(user, organization )) }
      it { expect(assignment.parent).to     eq(guide.progress_for(user, organization2)) }
      it { expect(guide.progress_for(user, organization)).not_to be_dirty_by_submission }
    end

  end
end
