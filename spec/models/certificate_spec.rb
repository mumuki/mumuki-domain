require 'spec_helper'

describe Certificate, organization_workspace: :test do

  let(:certificate) { create :certificate }

  context '#locals' do
    let(:locals) { certificate.locals }
    it { expect(locals.start_date).to_not be_nil }
    it { expect(locals.end_date).to_not be_nil }
    it { expect(locals.user.formal_first_name).to eq 'Jane' }
    it { expect(locals.user.formal_last_name).to eq 'Doe' }
    it { expect(locals.user.formal_full_name).to eq 'Jane Doe' }
    it { expect(locals.certification.title).to eq 'Test' }
    it { expect(locals.certification.description).to eq 'Certification to test' }
    it { expect(locals.organization.name).to eq 'test' }
    it { expect(locals.organization.display_name).to eq 'Test' }
  end

  context '#filename' do
    it { expect(certificate.filename).to eq 'test.pdf' }
  end
end
