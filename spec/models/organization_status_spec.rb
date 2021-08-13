require 'spec_helper'

describe Organization::Status, organization_workspace: :test do

  describe '#status' do
    let(:organization) { create :organization }

    context 'when organization is enabled' do
      it { expect(organization.status).to be_an_instance_of Organization::Status::Enabled }
      it { expect { organization.validate_active! }.not_to raise_error }
    end

    context 'when organization is in preparation' do
      before { organization.update! in_preparation_until: 1.day.since }
      it { expect(organization.status).to be_an_instance_of Organization::Status::InPreparation }
      it { expect { organization.validate_active! }.to raise_error Mumuki::Domain::UnpreparedOrganizationError }
    end

    context 'when organization is disabled' do
      before { organization.update! disabled_from: 1.day.ago }
      it { expect(organization.status).to be_an_instance_of Organization::Status::Disabled }
      it { expect { organization.validate_active! }.to raise_error Mumuki::Domain::DisabledOrganizationError }
    end
  end

  describe '#access_mode' do
    let(:organization) { create :organization, forum_enabled: true, public: false, faqs: 'FAQs' }
    let(:slug) { Mumukit::Auth::Slug.join_s organization.name, 'foo' }
    let(:course) { create :course, organization: organization, slug: slug }
    let(:user) { create :user }
    let(:access_mode) { organization.access_mode user }
    let(:exercise1) { create :exercise }
    let(:exercise2) { create :exercise }
    let(:discussion) { build :discussion, initiator: user }

    before { create :assignment, submitter: user, organization: organization, exercise: exercise1 }

    context 'in private organization' do
      context 'when organization is enabled' do
        context 'and user is teacher of organization' do
          before { user.update! permissions: { teacher: slug } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::Full }
          it { expect(access_mode.faqs_here?).to be true }
          it { expect(access_mode.profile_here?).to be true }
          it { expect(access_mode.discuss_here?).to be true }
          it { expect(access_mode.submit_solutions_here?).to be true }
          it { expect(access_mode.resolve_discussions_here?).to be true }
          it { expect(access_mode.show_content? exercise1).to be true }
          it { expect(access_mode.show_content? exercise2).to be true }
          it { expect(access_mode.show_discussion_element?).to be true }
          it { expect(access_mode.show_content_element?).to be true }
          it { expect { access_mode.validate_active! }.not_to raise_error }
          it { expect { access_mode.validate_content_here! exercise1 }.not_to raise_error }
          it { expect { access_mode.validate_discuss_here! discussion }.not_to raise_error }
        end

        context 'and user is student of organization' do
          before { user.update! permissions: { student: slug } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::Full }
          it { expect(access_mode.faqs_here?).to be true }
          it { expect(access_mode.profile_here?).to be true }
          it { expect(access_mode.discuss_here?).to be true }
          it { expect(access_mode.submit_solutions_here?).to be true }
          it { expect(access_mode.resolve_discussions_here?).to be true }
          it { expect(access_mode.show_content? exercise1).to be true }
          it { expect(access_mode.show_content? exercise2).to be true }
          it { expect(access_mode.show_discussion_element?).to be true }
          it { expect(access_mode.show_content_element?).to be true }
          it { expect { access_mode.validate_active! }.not_to raise_error }
          it { expect { access_mode.validate_content_here! exercise1 }.not_to raise_error }
          it { expect { access_mode.validate_content_here! exercise2 }.not_to raise_error }
          it { expect { access_mode.validate_discuss_here! discussion }.not_to raise_error }
        end

        context 'and user is ex student of organization' do
          before { user.update! permissions: { ex_student: slug } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::ReadOnly }
          it { expect(access_mode.faqs_here?).to be true }
          it { expect(access_mode.profile_here?).to be true }
          it { expect(access_mode.discuss_here?).to be true }
          it { expect(access_mode.submit_solutions_here?).to be false }
          it { expect(access_mode.resolve_discussions_here?).to be false }
          it { expect(access_mode.show_content? exercise1).to be true }
          it { expect(access_mode.show_content? exercise2).to be false }
          it { expect(access_mode.show_discussion_element?).to be false }
          it { expect(access_mode.show_content_element?).to be false }
          it { expect { access_mode.validate_active! }.not_to raise_error }
          it { expect { access_mode.validate_content_here! exercise1 }.not_to raise_error }
          it { expect { access_mode.validate_content_here! exercise2 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_discuss_here! discussion }.not_to raise_error }
        end

        context 'and user is outsider of organization' do
          before { user.update! permissions: { ex_student: '', student: '', teacher: '' } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::Forbidden }
          it { expect(access_mode.faqs_here?).to be false }
          it { expect(access_mode.profile_here?).to be false }
          it { expect(access_mode.discuss_here?).to be false }
          it { expect(access_mode.submit_solutions_here?).to be false }
          it { expect(access_mode.resolve_discussions_here?).to be false }
          it { expect(access_mode.show_content? exercise1).to be false }
          it { expect(access_mode.show_content? exercise2).to be false }
          it { expect(access_mode.show_discussion_element?).to be false }
          it { expect(access_mode.show_content_element?).to be false }
          it { expect { access_mode.validate_active! }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_content_here! exercise1 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_content_here! exercise2 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_discuss_here! discussion }.to raise_error Mumuki::Domain::ForbiddenError }
        end
      end

      context 'when organization is in preparation' do
        before { organization.update! in_preparation_until: 1.day.since }

        context 'and user is teacher of organization' do
          before { user.update! permissions: { teacher: slug } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::Full }
          it { expect(access_mode.faqs_here?).to be true }
          it { expect(access_mode.profile_here?).to be true }
          it { expect(access_mode.discuss_here?).to be true }
          it { expect(access_mode.submit_solutions_here?).to be true }
          it { expect(access_mode.resolve_discussions_here?).to be true }
          it { expect(access_mode.show_content? exercise1).to be true }
          it { expect(access_mode.show_content? exercise2).to be true }
          it { expect(access_mode.show_discussion_element?).to be true }
          it { expect(access_mode.show_content_element?).to be true }
          it { expect { access_mode.validate_active! }.not_to raise_error }
          it { expect { access_mode.validate_content_here! exercise1 }.not_to raise_error }
          it { expect { access_mode.validate_discuss_here! discussion }.not_to raise_error }
        end

        context 'and user is student of organization' do
          before { user.update! permissions: { student: slug } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::ComingSoon }
          it { expect(access_mode.faqs_here?).to be false }
          it { expect(access_mode.profile_here?).to be false }
          it { expect(access_mode.discuss_here?).to be false }
          it { expect(access_mode.submit_solutions_here?).to be false }
          it { expect(access_mode.resolve_discussions_here?).to be false }
          it { expect(access_mode.show_content? exercise1).to be false }
          it { expect(access_mode.show_content? exercise2).to be false }
          it { expect(access_mode.show_discussion_element?).to be false }
          it { expect(access_mode.show_content_element?).to be false }
          it { expect { access_mode.validate_active! }.to raise_error Mumuki::Domain::UnpreparedOrganizationError }
          it { expect { access_mode.validate_content_here! exercise1 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_content_here! exercise2 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_discuss_here! discussion }.to raise_error Mumuki::Domain::ForbiddenError }
        end

        context 'and user is ex student of organization' do
          before { user.update! permissions: { ex_student: slug } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::Forbidden }
          it { expect(access_mode.faqs_here?).to be false }
          it { expect(access_mode.profile_here?).to be false }
          it { expect(access_mode.discuss_here?).to be false }
          it { expect(access_mode.submit_solutions_here?).to be false }
          it { expect(access_mode.resolve_discussions_here?).to be false }
          it { expect(access_mode.show_content? exercise1).to be false }
          it { expect(access_mode.show_content? exercise2).to be false }
          it { expect(access_mode.show_discussion_element?).to be false }
          it { expect(access_mode.show_content_element?).to be false }
          it { expect { access_mode.validate_active! }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_content_here! exercise1 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_content_here! exercise2 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_discuss_here! discussion }.to raise_error Mumuki::Domain::ForbiddenError }
        end

        context 'and user is outsider of organization' do
          before { user.update! permissions: { ex_student: '', student: '', teacher: '' } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::Forbidden }
          it { expect(access_mode.faqs_here?).to be false }
          it { expect(access_mode.profile_here?).to be false }
          it { expect(access_mode.discuss_here?).to be false }
          it { expect(access_mode.submit_solutions_here?).to be false }
          it { expect(access_mode.resolve_discussions_here?).to be false }
          it { expect(access_mode.show_content? exercise1).to be false }
          it { expect(access_mode.show_content? exercise2).to be false }
          it { expect(access_mode.show_discussion_element?).to be false }
          it { expect(access_mode.show_content_element?).to be false }
          it { expect { access_mode.validate_active! }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_content_here! exercise1 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_content_here! exercise2 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_discuss_here! discussion }.to raise_error Mumuki::Domain::ForbiddenError }
        end
      end

      context 'when organization is disabled' do
        before { organization.update! disabled_from: 1.day.ago }

        context 'and user is teacher of organization' do
          before { user.update! permissions: { teacher: slug } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::Full }
          it { expect(access_mode.faqs_here?).to be true }
          it { expect(access_mode.profile_here?).to be true }
          it { expect(access_mode.discuss_here?).to be true }
          it { expect(access_mode.submit_solutions_here?).to be true }
          it { expect(access_mode.resolve_discussions_here?).to be true }
          it { expect(access_mode.show_content? exercise1).to be true }
          it { expect(access_mode.show_content? exercise2).to be true }
          it { expect(access_mode.show_discussion_element?).to be true }
          it { expect(access_mode.show_content_element?).to be true }
          it { expect { access_mode.validate_active! }.not_to raise_error }
          it { expect { access_mode.validate_content_here! exercise1 }.not_to raise_error }
          it { expect { access_mode.validate_discuss_here! discussion }.not_to raise_error }
        end

        context 'and user is student of organization' do
          before { user.update! permissions: { student: slug } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::ReadOnly }
          it { expect(access_mode.faqs_here?).to be true }
          it { expect(access_mode.profile_here?).to be true }
          it { expect(access_mode.discuss_here?).to be true }
          it { expect(access_mode.submit_solutions_here?).to be false }
          it { expect(access_mode.resolve_discussions_here?).to be false }
          it { expect(access_mode.show_content? exercise1).to be true }
          it { expect(access_mode.show_content? exercise2).to be true }
          it { expect(access_mode.show_discussion_element?).to be false }
          it { expect(access_mode.show_content_element?).to be false }
          it { expect { access_mode.validate_active! }.not_to raise_error }
          it { expect { access_mode.validate_content_here! exercise1 }.not_to raise_error }
          it { expect { access_mode.validate_content_here! exercise2 }.not_to raise_error }
          it { expect { access_mode.validate_discuss_here! discussion }.not_to raise_error }
        end

        context 'and user is ex student of organization' do
          before { user.update! permissions: { ex_student: slug } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::ReadOnly }
          it { expect(access_mode.faqs_here?).to be true }
          it { expect(access_mode.profile_here?).to be true }
          it { expect(access_mode.discuss_here?).to be false }
          it { expect(access_mode.submit_solutions_here?).to be false }
          it { expect(access_mode.resolve_discussions_here?).to be false }
          it { expect(access_mode.show_content? exercise1).to be false }
          it { expect(access_mode.show_content? exercise2).to be false }
          it { expect(access_mode.show_discussion_element?).to be false }
          it { expect(access_mode.show_content_element?).to be false }
          it { expect { access_mode.validate_active! }.not_to raise_error }
          it { expect { access_mode.validate_content_here! exercise1 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_content_here! exercise2 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_discuss_here! discussion }.not_to raise_error }
        end

        context 'and user is outsider of organization' do
          before { user.update! permissions: { ex_student: '', student: '', teacher: '' } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::Forbidden }
          it { expect(access_mode.faqs_here?).to be false }
          it { expect(access_mode.profile_here?).to be false }
          it { expect(access_mode.discuss_here?).to be false }
          it { expect(access_mode.submit_solutions_here?).to be false }
          it { expect(access_mode.resolve_discussions_here?).to be false }
          it { expect(access_mode.show_content? exercise1).to be false }
          it { expect(access_mode.show_content? exercise2).to be false }
          it { expect(access_mode.show_discussion_element?).to be false }
          it { expect(access_mode.show_content_element?).to be false }
          it { expect { access_mode.validate_active! }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_content_here! exercise1 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_content_here! exercise2 }.to raise_error Mumuki::Domain::ForbiddenError }
          it { expect { access_mode.validate_discuss_here! discussion }.to raise_error Mumuki::Domain::ForbiddenError }
        end
      end
    end
    context 'in public organization' do
      let(:organization) { create :public_organization }
      context 'when organization is enabled' do
        context 'and user is outsider of organization' do
          before { user.update! permissions: { ex_student: '', student: '', teacher: '' } }

          it { expect(access_mode).to be_an_instance_of OrganizationAccessMode::Full }
          it { expect(access_mode.faqs_here?).to be false }
          it { expect(access_mode.profile_here?).to be true }
          it { expect(access_mode.discuss_here?).to be false }
          it { expect(access_mode.submit_solutions_here?).to be true }
          it { expect(access_mode.resolve_discussions_here?).to be false }
          it { expect(access_mode.show_content? exercise1).to be true }
          it { expect(access_mode.show_content? exercise2).to be true }
          it { expect(access_mode.show_discussion_element?).to be true }
          it { expect(access_mode.show_content_element?).to be true }
          it { expect { access_mode.validate_active! }.not_to raise_error }
          it { expect { access_mode.validate_content_here! exercise1 }.not_to raise_error }
          it { expect { access_mode.validate_discuss_here! discussion }.not_to raise_error }
        end
      end
    end
  end

end
