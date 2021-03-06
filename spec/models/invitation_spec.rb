require 'spec_helper'

describe Invitation, organization_workspace: :test do
  let(:course) { create :course, slug: 'test/bar' }

  describe '.import_from_resource_h!' do
    let(:invitation) { Invitation.import_from_resource_h! code: 'eZNvuQ', course: course.slug, expiration_date: 2.days.since }

    it { expect(invitation).to_not be nil }
    it { expect(invitation.code).to eq 'eZNvuQ' }
    it { expect(invitation.course_slug).to eq 'test/bar' }
  end

  describe '#unexpired' do
    let(:invitation) { create(:invitation, expiration_date: 5.minutes.since, course: course) }
    context 'when expired' do
      it do
        invitation.update! expiration_date: 5.minutes.ago
        expect { invitation.reload.unexpired }.to raise_error Mumuki::Domain::GoneError
      end
    end
    context 'when not expired' do
      it { expect(invitation.unexpired).to eq invitation }
    end
  end
end
