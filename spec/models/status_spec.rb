require 'spec_helper'

describe Mumuki::Domain::Status do
  it { expect(Mumuki::Domain::Status::Submission::PassedWithWarnings.as_json).to eq 'passed_with_warnings' }
end
