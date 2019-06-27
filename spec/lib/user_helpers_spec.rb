require_relative '../spec_helper'

describe Mumuki::Domain::Helpers::User do
  let(:json) { {
    uid: 'foo@bar.com',
    image_url: 'image.png',
    email: 'foo@bar.com',
    first_name: 'Jon',
    last_name: 'Doe',
    permissions: {}} }
  let(:user) { User.new json }
  let(:organization) { Organization.new name: 'foo' }

  it { expect(user.name).to eq 'Jon Doe' }
  it { expect(user.full_name).to eq 'Jon Doe' }
  it { expect(user.writer?).to be false }
  it { expect(user.student?).to be false }
  it { expect(user.platform_event_name(:changed)).to eq 'UserChanged' }
  it { expect(user.as_platform_event).to eq user: user.to_resource_h }

  describe 'make_student_of!' do
    before { user.make_student_of! organization.slug }

    it { expect(user.student?).to be true }
    it { expect(user.student? 'bar/_').to be false }

    it { expect(user.student_of? organization).to be true }
    it { expect(user.student_of? struct(slug: 'bar/_')).to be false }
  end

  describe 'to_resource_h' do
    it { expect(user.to_resource_h).to json_eq json }
  end

  describe 'student_here?' do
    before { Mumukit::Platform::Organization.leave! }

    context 'no organization selected' do
      it { expect { user.student_here? }.to raise_error('organization not selected') }
    end

    context 'organization selected' do
      before { Mumukit::Platform::Organization.switch! organization }

      context 'when in organization' do
        before { user.make_student_of! organization.slug }
        it { expect(user.student_here?).to be true }
      end

      context 'when not in organization' do
        it { expect(user.student_here?).to be false }
      end
    end
  end


  describe 'discusser_here?' do
    before { Mumukit::Platform::Organization.leave! }

    context 'no organization selected' do
      it { expect { user.discusser_here? }.to raise_error('organization not selected') }
    end

    context 'organization selected' do
      before { Mumukit::Platform::Organization.switch! organization }
      before { organization.forum_discussions_minimal_role = :student }

      context 'when student is minimal discusser permission' do
        context 'when in organization not as student' do
          it { expect(user.discusser_here?).to be false }
        end

        context 'when in organization as student' do
          before { user.make_student_of! organization.slug }
          it { expect(user.discusser_here?).to be true }
        end
      end

      context 'when teacher is minimal discusser permission' do
        before { organization.forum_discussions_minimal_role = :teacher }

        context 'when in organization not as student' do
          it { expect(user.discusser_here?).to be false }
        end

        context 'when in organization as student' do
          before { user.make_student_of! organization.slug }
          it { expect(user.discusser_here?).to be false }
        end

        context 'when in organization as teacher' do
          before { user.make_teacher_of! organization.slug }
          it { expect(user.discusser_here?).to be true }
        end
      end

      context 'when not in organization' do
        it { expect(user.discusser_here?).to be false }
      end
    end
  end

  describe 'student_granted_organizations' do
    before { Mumukit::Platform.config.organization_class = class_double('UserSpecDemoOrganization') }

    context 'no organization' do
      it { expect(user.student_granted_organizations).to eq [] }
      it { expect(user.has_student_granted_organizations?).to be false }
      it { expect(user.has_main_organization?).to be false }
      it { expect(user.has_immersive_main_organization?).to be false }
    end

    context 'with organization' do
      before { user.make_student_of! organization.slug }
      before { expect(Mumukit::Platform.organization_class).to receive(:find_by_name!).and_return(organization)}

      it { expect(user.student_granted_organizations).to eq [organization] }
      it { expect(user.has_student_granted_organizations?).to be true }
      it { expect(user.has_main_organization?).to be true }
      it { expect(user.has_immersive_main_organization?).to be false }

      context 'when immersive' do
        before { organization.settings.immersive = true }
        it { expect(user.has_immersive_main_organization?).to be true }
      end
    end
  end
end
