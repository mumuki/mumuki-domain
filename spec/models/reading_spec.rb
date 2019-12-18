require 'spec_helper'

describe Reading, organization_workspace: :test do
  let(:guide) { create(:indexed_guide) }
  let!(:reading) { create(:reading, guide: guide) }
  let!(:user) { create(:user) }

  let!(:result) { reading.submit_confirmation!(user) }

  it { expect(result).to eq status: :passed, result: '' }
end
