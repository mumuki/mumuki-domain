describe Invitation, organization_workspace: :test do
  describe '.import_from_resource_h!' do
    let!(:course) { create :course, slug: 'test/bar' }
    let(:invitation) { Invitation.import_from_resource_h! code: 'eZNvuQ', course: 'test/bar', expiration_date: 2.days.since }

    it { expect(invitation).to_not be nil }
    it { expect(invitation.code).to eq 'eZNvuQ' }
    it { expect(invitation.course.slug).to eq 'test/bar' }
  end
end
