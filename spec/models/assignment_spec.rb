require 'spec_helper'

describe Assignment, organization_workspace: :test do

  let(:gobstones) { create(:language, visible_success_output: true) }
  let(:haskell) { create(:haskell) }

  describe 'messages' do
    let(:student) { create(:user) }
    let(:problem) { create(:problem, manual_evaluation: true) }
    let(:assignment) { problem.assignment_for(student) }
    let(:message) { assignment.messages.first }

    before { problem.submit_solution! student, content: '...' }

    describe '.send_question!' do
      before { problem.submit_question! student, content: 'How can i solve this?' }

      it { expect(assignment.new_record?).to be false }
      it { expect(assignment.has_messages?).to be true }
      it { expect(message.sender).to eq student.uid }
      it { expect(message.content).to eq 'How can i solve this?' }
      it { expect(message.read).to be true }
      it { expect(message.assignment).to eq assignment }
      it { expect(message.submission_id).to eq assignment.submission_id }
      it { expect(message.date).to_not be nil }
      it { expect(assignment.organization).to eq Organization.current }
    end

    describe '.receive_answer!' do
      before { problem.submit_question! student, content: 'How can i solve this?' }
      before { assignment.receive_answer! sender: 'bot@mumuki.org', content: 'Check this link' }

      it { expect(assignment.has_messages?).to be true }
      it { expect(assignment.messages.count).to eq 2 }
      it { expect(message.sender).to eq 'bot@mumuki.org' }
      it { expect(message.content).to eq 'Check this link' }
      it { expect(message.read).to be false }
      it { expect(message.assignment).to eq assignment }
      it { expect(message.submission_id).to eq assignment.submission_id }
      it { expect(assignment.organization).to eq Organization.current }
    end
  end

  describe 'manual evaluation' do
    let(:user) { create(:user) }
    let(:exercise) { create(:exercise, manual_evaluation: true, test: nil, expectations: []) }
    let(:assignment) { exercise.submit_solution!(user, content: '') }

    it { expect(assignment.status).to eq :manual_evaluation_pending }
  end

  describe '#single_visual_result?' do
    let(:gobstones_exercise) { create(:indexed_exercise, language: gobstones) }
    let(:haskell_exercise) { create(:indexed_exercise, language: haskell) }

    let(:failed_submission_single_untitled_test) { create(:assignment, exercise: gobstones_exercise, status: :failed, test_results: [{status: :failed, title: '', result: 'result'}]) }
    let(:failed_submission_single_test) { create(:assignment, exercise: gobstones_exercise, status: :failed, test_results: [{status: :failed, title: 'ups', result: 'result'}]) }
    let(:failed_submission_multi_test) { create(:assignment, exercise: gobstones_exercise, status: :failed, test_results: [{status: :failed, title: 'ups', result: 'result'}, {status: :failed, title: 'upsy', result: 'result'}]) }
    let(:failed_submission_single_test_non_visual_exercise) { create(:assignment, exercise: haskell_exercise, status: :failed, test_results: [{status: :failed, title: 'ups', result: 'result'}]) }

    it { expect(failed_submission_single_untitled_test).to be_single_visual_result }
    it { expect(failed_submission_single_test).to_not be_single_visual_result }

    it { expect(failed_submission_single_untitled_test).to be_single_visible_test_result }
    it { expect(failed_submission_single_test).to be_single_visible_test_result }

    it { expect(failed_submission_single_test_non_visual_exercise).to_not be_single_visible_test_result }
    it { expect(failed_submission_multi_test).to_not be_single_visible_test_result }

    it { expect(failed_submission_single_test.first_test_result_html).to eq '<pre>result</pre>' }
  end

  describe '#results_body_hidden?' do
    let(:gobstones_exercise) { create(:indexed_exercise, language: gobstones) }
    let(:exercise) { create(:indexed_exercise, language: haskell) }

    let(:failed_submission) { create(:assignment, status: :failed) }
    let(:passed_submission) { create(:assignment, status: :passed, expectation_results: [], exercise: exercise) }
    let(:skipped_submission) { create(:assignment, status: :skipped, expectation_results: [], exercise: exercise) }
    let(:passed_submission_with_visible_output_language) { create(:assignment, status: :passed, exercise: gobstones_exercise) }
    let(:skipped_submission_with_visible_output_language) { create(:assignment, status: :skipped, exercise: gobstones_exercise) }
    let(:manual_evaluation_pending_submission) { create(:assignment, status: :manual_evaluation_pending) }

    it { expect(passed_submission.results_body_hidden?).to be true }
    it { expect(skipped_submission.results_body_hidden?).to be true }
    it { expect(failed_submission.results_body_hidden?).to be false }
    it { expect(skipped_submission_with_visible_output_language.results_body_hidden?).to be true }
    it { expect(passed_submission_with_visible_output_language.results_body_hidden?).to be false }
    it { expect(manual_evaluation_pending_submission.results_body_hidden?).to be true }
  end

  describe '#expectation_results_visible?' do
    let(:exercise) { create(:exercise) }

    context 'should show expectation with failed submissions' do
      let(:failed_submission) { create(:assignment, status: :failed, expectation_results: [{binding: "foo", inspection: "HasBinding", result: :failed}]) }
      it { expect(failed_submission.expectation_results_visible?).to be true }
      it { expect(failed_submission.failed_expectation_results.size).to eq 1 }
    end

    context 'should show expectation with errored submissions' do
      let(:errored_submission) { create(:assignment, status: :errored, expectation_results: [{binding: "foo", inspection: "HasBinding", result: :failed}]) }
      it { expect(errored_submission.expectation_results_visible?).to be true }
    end
  end

  describe '#showable_results_visible?' do
    let(:failed_submission) { create(:assignment, exercise: problem, status: :failed, expectation_results: [{binding: "foo", inspection: "HasBinding", result: :failed},
                                                                                                            {binding: "bar", inspection: "HasBinding", result: :failed}]) }

    context 'should show all failed expectation results for regular problems' do
      let(:problem) { create(:problem) }
      it { expect(failed_submission.visible_expectation_results.size).to eq 2 }
    end

    context 'should show only the first failed expectation result for kids problems' do
      let(:problem) { create(:problem, layout: 'input_kids') }
      it { expect(failed_submission.visible_expectation_results.size).to eq 1 }
    end
  end

  describe '#run_update!' do
    let(:exercise) { create(:indexed_exercise) }
    let(:assignment) { create(:assignment, exercise: exercise) }

    context 'when run passes unstructured' do
      before { assignment.run_update! { {result: 'ok', status: :passed} } }
      it { expect(assignment.status).to eq(:passed) }
      it { expect(assignment.result).to eq('ok') }
    end

    context 'when run fails unstructured' do
      before { assignment.run_update! { {result: 'ups', status: :failed} } }
      it { expect(assignment.status).to eq(:failed) }
      it { expect(assignment.result).to eq('ups') }
    end

    context 'when run aborts unstructured' do
      before { assignment.run_update! { {result: 'took more thn 4 seconds', status: :aborted} } }
      it { expect(assignment.status).to eq(:aborted) }
      it { expect(assignment.result).to eq('took more thn 4 seconds') }
    end

    context 'when run skips unstructured' do
      before { assignment.run_update! { {result: 'skip', status: :skipped} } }
      it { expect(assignment.status).to eq(:skipped) }
      it { expect(assignment.result).to eq('skip') }
    end

    context 'when run passes with warnings unstructured' do
      let(:runner_response) do
        {status: :passed_with_warnings,
         test_results: [{title: 'true is true', status: :passed, result: ''},
                        {title: 'false is false', status: :passed, result: ''}],
         expectation_results: [{binding: 'bar', inspection: 'HasBinding', result: :passed},
                               {binding: 'foo', inspection: 'HasBinding', result: :failed}],
         feedback: 'foo'}
      end
      before { assignment.run_update! { runner_response } }

      it { expect(assignment.status).to eq(:passed_with_warnings) }
      it { expect(assignment.result).to be_blank }
      it { expect(assignment.test_results).to eq(runner_response[:test_results]) }
      it { expect(assignment.expectation_results).to eq(runner_response[:expectation_results]) }
      it { expect(assignment.feedback).to eq('foo') }
    end

    context 'when run raises exception' do
      before do
        begin
          assignment.run_update! { raise 'ouch' }
        rescue
        end
      end
      it { expect(assignment.status).to eq(:errored) }
      it { expect(assignment.result).to eq('ouch') }
    end
  end

  describe '#update_submissions_count!' do
    let(:exercise) { create(:exercise) }
    let(:user) { create(:user) }

    before do
      exercise.submit_solution!(user)
      exercise.submit_solution!(user)
      exercise.submit_solution!(user)
    end

    it { expect(exercise.reload.submissions_count).to eq(3) }
    it { expect(exercise.assignments.first.organization).to eq Organization.current }
  end

  describe 'organization' do
    let(:exercise) { create(:exercise) }
    let(:user) { create(:user) }
    let(:chapter) { create(:chapter, lessons: [ create(:lesson, exercises: [exercise] )]) }
    let(:new_organization) { create(:organization, book: create(:book, chapters: [chapter] )) }

    before { exercise.submit_solution!(user, content: 'foo') }

    context 'when solution is submitted for the first time' do
      it 'should persist what organization it was submitted in' do
        expect(exercise.assignment_for(user).organization).to eq Organization.current
      end
    end

    context 'when solution is submitted after the assignment was created without an organization' do
      before { exercise.assignment_for(user).update_column(:organization_id, nil) }
      before { exercise.submit_solution!(user, content: 'foo') }

      it 'should persist what organization it was submitted in' do
        expect(exercise.assignment_for(user).organization).to eq Organization.current
      end
    end

    context 'when solution is submitted after the assignment was created' do
      before { new_organization.switch! }
      before { reindex_current_organization! }
      before { exercise.submit_solution!(user, content: 'foo') }

      it 'should persist what organization it was submitted in' do
        expect(exercise.assignment_for(user).organization).to eq new_organization
      end
    end
  end

  describe '#submission_id' do
    let(:exercise) { create(:exercise) }
    let(:user) { create(:user) }

    before { exercise.submit_solution!(user, content: 'foo') }

    it do
      submission_id = exercise.assignment_for(user).submission_id
      expect(submission_id).to be_present

      exercise.submit_solution!(user, content: 'bar')

      new_submission_id = exercise.assignment_for(user).submission_id
      expect(new_submission_id).to be_present
      expect(new_submission_id).to_not eq submission_id
    end
  end

  describe '#evaluate_manually!' do
    let(:user) { create(:user) }
    let(:exercise) { create(:exercise, manual_evaluation: true, test: nil, expectations: []) }
    let(:assignment) { exercise.submit_solution!(user, content: '') }
    let(:evaluated_assignment) { Assignment.find assignment.id }

    before { Assignment.evaluate_manually! submission_id: assignment.submission_id, manual_evaluation: '**Good**', status: 'passed_with_warnings' }

    it { expect(evaluated_assignment.status).to eq :passed_with_warnings }
    it { expect(evaluated_assignment.manual_evaluation_comment).to eq '**Good**' }
  end

  describe '#extra' do
    let(:user) { create(:user, email: 'some_email', first_name: 'some_first_name', last_name: 'some_last_name') }
    let(:exercise) { create(:exercise, extra: "/*...user_email...*/\n/*...user_first_name...*/\n/*...user_last_name...*/") }
    let(:assignment) { exercise.submit_solution!(user, content: '') }

    it { expect(assignment.extra).to eq "some_email\nsome_first_name\nsome_last_name\n" }
  end

  describe 'submission status' do
    let(:exercise) { create(:indexed_exercise) }
    let(:assignment) { create(:assignment, exercise: exercise, status: submission_status) }

    context 'pending' do
      let(:submission_status) { :pending }

      it 'does not need retrying' do
        expect(assignment.should_retry?).to be false
      end

      it 'is not solved nor completed' do
        expect(assignment.solved?).to be false
        expect(assignment.completed?).to be false
      end
    end

    context 'running' do
      let(:submission_status) { :running }

      it 'does not need retrying' do
        expect(assignment.should_retry?).to be false
      end

      it 'is not solved nor completed' do
        expect(assignment.solved?).to be false
        expect(assignment.completed?).to be false
      end
    end

    context 'passed' do
      let(:submission_status) { :passed }

      it 'does not need retrying' do
        expect(assignment.should_retry?).to be false
      end

      it 'is solved and completed' do
        expect(assignment.solved?).to be true
        expect(assignment.completed?).to be true
      end
    end

    context 'failed' do
      let(:submission_status) { :failed }

      it 'needs retrying' do
        expect(assignment.should_retry?).to be true
      end

      it 'is not solved nor completed' do
        expect(assignment.solved?).to be false
        expect(assignment.completed?).to be false
      end
    end

    context 'errored' do
      let(:submission_status) { :errored }

      it 'needs retrying' do
        expect(assignment.should_retry?).to be true
      end

      it 'is not solved nor completed' do
        expect(assignment.solved?).to be false
        expect(assignment.completed?).to be false
      end
    end

    context 'aborted' do
      let(:submission_status) { :aborted }

      it 'does not need retrying' do
        expect(assignment.should_retry?).to be false
      end

      it 'is not solved nor completed' do
        expect(assignment.solved?).to be false
        expect(assignment.completed?).to be false
      end
    end

    context 'passed with warnings' do
      let(:submission_status) { :passed_with_warnings }

      it 'needs retrying' do
        expect(assignment.should_retry?).to be true
      end

      it 'is not solved nor completed' do
        expect(assignment.solved?).to be false
        expect(assignment.completed?).to be false
      end
    end

    context 'manual evaluation pending' do
      let(:submission_status) { :manual_evaluation_pending }

      it 'does not need retrying' do
        expect(assignment.should_retry?).to be false
      end

      it 'is not solved nor completed' do
        expect(assignment.solved?).to be false
        expect(assignment.completed?).to be false
      end
    end

    context 'skipped' do
      let(:submission_status) { :skipped }

      it 'does not need retrying' do
        expect(assignment.should_retry?).to be false
      end

      it 'is solved and completed' do
        expect(assignment.solved?).to be true
        expect(assignment.completed?).to be true
      end
    end
  end
end
