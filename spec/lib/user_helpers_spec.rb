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

  describe "profile_completed?" do
    let(:empty) { User.new }
    let(:name_only) { User.new first_name: 'Julio', last_name: 'Cortazar' }
    let(:with_gender) { User.new first_name: 'Victoria', last_name: 'Ocampo', gender: :female }
    let(:complete) { User.new first_name: 'Maria Elena', last_name: 'Walsh', gender: :female, birthdate: Date.new(1930, 2, 1) }

    it { expect(empty).to_not be_profile_completed }
    it { expect(name_only).to_not be_profile_completed }
    it { expect(with_gender).to_not be_profile_completed }
    it { expect(complete).to be_profile_completed }
  end

  describe 'make_student_of!' do
    before { user.make_student_of! organization }

    it { expect(user.student?).to be true }
    it { expect(user.student? 'bar/_').to be false }

    it { expect(user.student_of? organization).to be true }
    it { expect(user.student_of? 'bar/_').to be false }
  end

  describe 'to_resource_h' do
    context 'when user has no avatar' do
      it { expect(user.to_resource_h)
               .to json_eq(
                       uid: json[:uid],
                       image_url: json[:image_url],
                       email: json[:email],
                       first_name: json[:first_name],
                       last_name: json[:last_name],
                       permissions: json[:permissions]
                   )
      }
    end

    context 'when user has avatar' do
      let(:avatar) { Avatar.new(image_url: 'avatar.png') }

      before { json[:avatar] = avatar }

      it { expect(user.to_resource_h)
               .to json_eq(
                       uid: json[:uid],
                       image_url: avatar.image_url,
                       email: json[:email],
                       first_name: json[:first_name],
                       last_name: json[:last_name],
                       permissions: json[:permissions]
                   )
      }
    end
  end

  describe 'student_here?' do
    before { Mumukit::Platform::Organization.leave! }

    context 'no organization selected' do
      it { expect { user.student_here? }.to raise_error('organization not selected') }
    end

    context 'organization selected' do
      before { Mumukit::Platform::Organization.switch! organization }

      context 'when in organization' do
        before { user.make_student_of! organization }
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
          before { user.make_student_of! organization }
          it { expect(user.discusser_here?).to be true }
        end
      end

      context 'when teacher is minimal discusser permission' do
        before { organization.forum_discussions_minimal_role = :teacher }

        context 'when in organization not as student' do
          it { expect(user.discusser_here?).to be false }
        end

        context 'when in organization as student' do
          before { user.make_student_of! organization }
          it { expect(user.discusser_here?).to be false }
        end

        context 'when in organization as teacher' do
          before { user.make_teacher_of! organization }
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
    after { Mumukit::Platform.config.organization_class = nil }

    context 'no organization' do
      it { expect(user.student_granted_organizations).to eq [] }
      it { expect(user.has_student_granted_organizations?).to be false }
      it { expect(user.has_immersive_main_organization?).to be false }
      it { expect(user.immersive_main_organization).to be nil }
    end

    context 'with organization' do
      before { user.make_student_of! organization }
      before { expect(Mumukit::Platform.organization_class).to receive(:find_by_name!).and_return(organization)}

      it { expect(user.student_granted_organizations).to eq [organization] }
      it { expect(user.has_student_granted_organizations?).to be true }
      it { expect(user.has_immersive_main_organization?).to be false }
      it { expect(user.immersive_main_organization).to be nil }

      context 'when immersive' do
        before { organization.settings.immersive = true }
        it { expect(user.immersive_main_organization).to eq organization }
      end
    end
  end
end
