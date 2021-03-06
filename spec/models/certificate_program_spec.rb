require 'spec_helper'

describe CertificateProgram, organization_workspace: :test do

  let!(:certificate_program) { create(:certificate_program, end_date: certificate_program_end_date, start_date: certificate_program_start_date) }
  let(:certificate_program_end_date) { nil }
  let(:certificate_program_start_date) { nil }

  describe '.ongoing' do
    context 'with no end or start_date' do
      it { expect(CertificateProgram.ongoing.count).to eq 1 }
    end

    context 'with end_date in the future and no start_date' do
      let(:certificate_program_end_date) { 5.minutes.since }

      it { expect(CertificateProgram.ongoing.count).to eq 1 }
    end

    context 'with end_date in the past and no start_date' do
      let(:certificate_program_end_date) { 5.minutes.ago }

      it { expect(CertificateProgram.ongoing.count).to eq 0 }
    end

    context 'with start_date in the past and no end_date' do
      let(:certificate_program_start_date) { 5.minutes.ago }

      it { expect(CertificateProgram.ongoing.count).to eq 1 }
    end

    context 'with start_date in the future and no end_date' do
      let(:certificate_program_start_date) { 5.minutes.since }

      it { expect(CertificateProgram.ongoing.count).to eq 0 }
    end

    context 'with end_date in the future and start_date in the past' do
      let(:certificate_program_end_date) { 5.minutes.since }
      let(:certificate_program_start_date) { 5.minutes.ago }

      it { expect(CertificateProgram.ongoing.count).to eq 1 }
    end

    context 'with both end_date and start_date in the future' do
      let(:certificate_program_end_date) { 5.minutes.since }
      let(:certificate_program_start_date) { 5.minutes.since }

      it { expect(CertificateProgram.ongoing.count).to eq 0 }
    end

    context 'with both end_date and start_date in the past' do
      let(:certificate_program_end_date) { 5.minutes.ago }
      let(:certificate_program_start_date) { 5.minutes.ago }

      it { expect(CertificateProgram.ongoing.count).to eq 0 }
    end

    context 'with actually_filter disabled' do
      let(:certificate_program_end_date) { 5.minutes.ago }
      let(:certificate_program_start_date) { 5.minutes.ago }

      it { expect(CertificateProgram.ongoing(false).count).to eq 1 }
    end
  end
end
