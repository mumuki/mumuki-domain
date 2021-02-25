require 'spec_helper'

describe Certificate, organization_workspace: :test do

  let(:certificate) { create :certificate }

  context '#tmplate_locals' do
    let(:locals) { certificate.template_locals.to_struct }
    it { expect(locals.certificate.start_date).to_not be_nil }
    it { expect(locals.certificate.end_date).to_not be_nil }
    it { expect(locals.user.formal_first_name).to eq 'Jane' }
    it { expect(locals.user.formal_last_name).to eq 'Doe' }
    it { expect(locals.user.formal_full_name).to eq 'Jane Doe' }
    it { expect(locals.certificate_program.title).to eq 'Test' }
    it { expect(locals.certificate_program.description).to eq 'Certificate program to test' }
    it { expect(locals.organization.name).to eq 'test' }
    it { expect(locals.organization.display_name).to eq 'Test' }
  end

  context '#filename' do
    it { expect(certificate.filename).to eq 'test.pdf' }
  end
end
