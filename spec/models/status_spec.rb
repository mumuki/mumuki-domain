require 'spec_helper'

describe Mumuki::Domain::Status do
  describe 'discussion' do
    it { expect(Mumuki::Domain::Status::Discussion::PendingReview.as_json).to eq 'pending_review' }
  end

  describe 'discussion' do
    it { expect(Mumuki::Domain::Status::Submission::PassedWithWarnings.as_json).to eq 'passed_with_warnings' }
  end
end
