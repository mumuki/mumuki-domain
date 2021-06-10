require 'spec_helper'

describe WithResponsibleModerator, organization_workspace: :test do
  let(:student) { create(:user, permissions: {student: 'test/*'}) }
  let(:discussion) { create(:exercise).discuss! student, title: 'Need help' }
  let(:moderator) { create(:user, permissions: {student: 'test/*', moderator: 'test/*'}) }
  let(:another_moderator) { create(:user, permissions: {student: 'test/*', moderator: 'test/*'}) }

  describe '#toggle_responsible!' do
    context 'when no one is responsible' do
      before { discussion.toggle_responsible! moderator }

      it { expect(discussion.any_responsible?).to be true }
      it { expect(discussion.responsible? moderator).to be true }
    end

    context 'when moderator is already responsible' do
      before do
        discussion.update! responsible_moderator_by: moderator, responsible_moderator_at: Time.now
        discussion.toggle_responsible! moderator
      end

      it { expect(discussion.any_responsible?).to be false }
      it { expect(discussion.responsible? moderator).to be false }
    end

    context 'when another moderator is already responsible' do
      before do
        discussion.update! responsible_moderator_by: another_moderator, responsible_moderator_at: Time.now
        discussion.toggle_responsible! moderator
      end

      it { expect(discussion.any_responsible?).to be true }
      it { expect(discussion.responsible? moderator).to be false }
    end

    describe '#any_responsible?' do
      context 'when a discussion is new' do
        it { expect(discussion.any_responsible?).to be false }
      end

      context 'when a moderator is responsible' do
        before { discussion.update! responsible_moderator_by: moderator, responsible_moderator_at: Time.now }

        it { expect(discussion.any_responsible?).to be true }
      end

      context 'when a moderator was responsible but too much time passed' do
        before { discussion.update! responsible_moderator_by: moderator, responsible_moderator_at: Time.now - 1.hour }

        it { expect(discussion.any_responsible?).to be false }
      end
    end

    describe '#responsible?' do
      context 'when discussion has no responsible' do
        it { expect(discussion.responsible? moderator).to be false }
      end

      context 'when a moderator is responsible' do
        before { discussion.update! responsible_moderator_by: moderator, responsible_moderator_at: Time.now }

        it { expect(discussion.responsible? moderator).to be true }
      end

      context 'when another moderator is responsible' do
        before { discussion.update! responsible_moderator_by: another_moderator, responsible_moderator_at: Time.now }

        it { expect(discussion.responsible? moderator).to be false }
      end

      context 'when a moderator was responsible but too much time passed' do
        before { discussion.update! responsible_moderator_by: moderator, responsible_moderator_at: Time.now - 1.hour }

        it { expect(discussion.responsible? moderator).to be false }
      end
    end

    describe '#current_responsible_visible_for?' do
      context 'when there is a responsible' do
        before { discussion.update! responsible_moderator_by: moderator, responsible_moderator_at: Time.now }

        context 'when user is a student' do
          it { expect(discussion.current_responsible_visible_for? student).to be false }
        end

        context 'when user is a moderator' do
          it { expect(discussion.current_responsible_visible_for? moderator).to be true }
        end
      end

      context 'when there is no responsible' do
        context 'when user is a student' do
          it { expect(discussion.current_responsible_visible_for? student).to be false }
        end

        context 'when user is a moderator' do
          it { expect(discussion.current_responsible_visible_for? moderator).to be false }
        end
      end
    end

    describe '#can_toggle_responsible?' do
      context 'when there is a responsible' do
        before { discussion.update! responsible_moderator_by: moderator, responsible_moderator_at: Time.now }

        context 'when user is a student' do
          it { expect(discussion.can_toggle_responsible? student).to be false }
        end

        context 'when user is the responsible moderator' do
          it { expect(discussion.can_toggle_responsible? moderator).to be true }
        end

        context 'when user is another moderator' do
          it { expect(discussion.can_toggle_responsible? another_moderator).to be false }
        end
      end

      context 'when there is no responsible' do
        context 'when user is a student' do
          it { expect(discussion.can_toggle_responsible? student).to be false }
        end

        context 'when user is a moderator' do
          context 'when discussion is open' do
            it { expect(discussion.can_toggle_responsible? moderator).to be true }
          end

          context 'when discussion is pending review' do
            before { discussion.update! status: Mumuki::Domain::Status::Discussion::PendingReview }
            it { expect(discussion.can_toggle_responsible? moderator).to be true }
          end

          context 'when discussion is closed' do
            before { discussion.update! status: Mumuki::Domain::Status::Discussion::Closed }
            it { expect(discussion.can_toggle_responsible? moderator).to be false }
          end

          context 'when discussion is solved' do
            before { discussion.update! status: Mumuki::Domain::Status::Discussion::Solved }
            it { expect(discussion.can_toggle_responsible? moderator).to be false }
          end
        end
      end
    end
  end
end
