require 'spec_helper'

describe Mumuki::Domain::Status::Submission do
  let(:submission) { Mumuki::Domain::Status::Submission }

  let(:aborted)                   { submission::Aborted }
  let(:errored)                   { submission::Errored }
  let(:failed)                    { submission::Failed }
  let(:manual_evaluation_pending) { submission::ManualEvaluationPending }
  let(:passed)                    { submission::Passed }
  let(:passed_with_warnings)      { submission::PassedWithWarnings }
  let(:pending)                   { submission::Pending }
  let(:running)                   { submission::Running }
  let(:skipped)                   { submission::Skipped }

  let(:statuses) { submission::STATUSES }
  let(:exp_statuses) { [passed, passed_with_warnings, skipped] }
  let(:no_exp_statuses) { statuses - exp_statuses }

  describe 'aborted' do
    it { expect(aborted.exp_given).to be 0 }
    it { expect(   exp_statuses.all? { |status| aborted.improved_by?(status) }).to be true  }
    it { expect(no_exp_statuses.all? { |status| aborted.improved_by?(status) }).to be false }
  end

  describe 'errored' do
    it { expect(errored.exp_given).to be 0 }
    it { expect(   exp_statuses.all? { |status| errored.improved_by?(status) }).to be true  }
    it { expect(no_exp_statuses.all? { |status| errored.improved_by?(status) }).to be false }
  end

  describe 'failed' do
    it { expect(failed.exp_given).to be 0 }
    it { expect(   exp_statuses.all? { |status| failed.improved_by?(status) }).to be true  }
    it { expect(no_exp_statuses.all? { |status| failed.improved_by?(status) }).to be false }
  end

  describe 'manual_evaluation_pending' do
    it { expect(manual_evaluation_pending.exp_given).to be 0 }
    it { expect(   exp_statuses.all? { |status| manual_evaluation_pending.improved_by?(status) }).to be true  }
    it { expect(no_exp_statuses.all? { |status| manual_evaluation_pending.improved_by?(status) }).to be false }
  end

  describe 'passed' do
    it { expect(passed.exp_given).to be 100 }
    it { expect(statuses.all? { |status| passed.improved_by?(status) }).to be false }
  end

  describe 'passed_with_warnings' do
    let(:solved_statuses) { exp_statuses - [passed_with_warnings] }

    it { expect(passed_with_warnings.exp_given).to be 50 }
    it { expect(solved_statuses.all? { |status| passed_with_warnings.improved_by?(status) }).to be true }
    it { expect(no_exp_statuses.all? { |status| passed_with_warnings.improved_by?(status) }).to be false }
  end

  describe 'pending' do
    it { expect(pending.exp_given).to be 0 }
    it { expect(   exp_statuses.all? { |status| pending.improved_by?(status) }).to be true  }
    it { expect(no_exp_statuses.all? { |status| pending.improved_by?(status) }).to be false }
  end

  describe 'running' do
    it { expect(running.exp_given).to be 0 }
    it { expect(   exp_statuses.all? { |status| running.improved_by?(status) }).to be true  }
    it { expect(no_exp_statuses.all? { |status| running.improved_by?(status) }).to be false }
  end

  describe 'skipped' do
    it { expect(skipped.exp_given).to be 100 }
    it { expect(statuses.all? { |status| skipped.improved_by?(status) }).to be false }
  end
end
