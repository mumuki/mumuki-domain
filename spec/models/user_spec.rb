require 'spec_helper'

describe User, organization_workspace: :test do

  context 'can not have a null or empty uid' do
    it { expect { User.create! uid: nil }.to raise_error ActiveRecord::RecordInvalid }
    it { expect { User.create! uid: '' }.to raise_error ActiveRecord::RecordInvalid }
  end

  describe '#clear_progress!' do
    let(:student) { create :user }
    let(:more_clauses) { create(:exercise, name: 'More Clauses') }

    before { more_clauses.submit_solution! student, content: 'foo(X) :- not(bar(X))' }

    before { student.reload.clear_progress! }

    it { expect(student.reload.assignments).to be_empty }
    it { expect(student.never_submitted?).to be true }
  end

  describe '#transfer_progress_to!' do

    let(:codeorga) { build :organization, name: 'code.orga' }
    let(:prologschool) { build :organization, name: 'prologschool' }

    let(:your_first_program) { build(:exercise, name: 'Your First Program') }
    let(:more_clauses) { build(:exercise, name: 'More Clauses') }

    let(:two_hours_ago) { 2.hours.ago }

    context 'when final user has less information than original' do
      let!(:submission) { your_first_program.submit_solution! original, content: 'adasdsadas' }

      before { original.reload.transfer_progress_to! final }

      let(:original) { create :user,
                              permissions: {student: 'codeorga/*'},
                              first_name: 'johnny',
                              last_name: 'doe',
                              social_id: 'auth0|123456',
                              last_organization: codeorga }

      let(:final) { create :user,
                           permissions: Mumukit::Auth::Permissions.new,
                           first_name: 'John',
                           last_name: 'Doe',
                           social_id: 'auth0|345678' }

      it { expect(final.name).to eq 'John Doe' }
      it { expect(final.social_id).to eq 'auth0|345678' }

      it { expect(final.last_submission_date).to eq original.last_submission_date }
      it { expect(final.last_organization).to eq codeorga }
      it { expect(final.last_exercise).to eq your_first_program }

      it { expect(final.permissions.as_json).to json_like({}) }

      it { expect(submission.reload.submitter).to eq final }
    end

    context 'when final user has more information than original' do
      before { more_clauses.submit_solution! final, content: 'adasdsadas' }
      before { original.transfer_progress_to! final.reload }

      let(:original) { create :user,
                              permissions: Mumukit::Auth::Permissions.new,
                              first_name: 'johnny',
                              last_name: 'doe',
                              social_id: 'auth0|123456' }
      let(:final) { create :user,
                           permissions: {student: 'prologschool/*'},
                           first_name: 'John',
                           last_name: 'Doe',
                           social_id: 'auth0|345678',
                           last_organization: prologschool }

      it { expect(final.name).to eq 'John Doe' }
      it { expect(final.social_id).to eq 'auth0|345678' }

      it { expect(final.last_submission_date).to_not be nil }
      it { expect(final.last_organization).to eq prologschool }
      it { expect(final.last_exercise).to eq more_clauses }

      it { expect(final.permissions.as_json).to json_like student: 'prologschool/*' }
    end

    context 'when both have information, but final is newer' do
      before { original.transfer_progress_to! final }

      let(:original) { create :user,
                              permissions: {student: 'codeorga/*'},
                              first_name: 'johnny',
                              last_name: 'doe',
                              social_id: 'auth0|123456',
                              last_submission_date: 6.hours.ago,
                              last_organization: codeorga,
                              last_exercise: your_first_program }
      let(:final) { create :user,
                           permissions: {student: 'prologschool/*'},
                           first_name: 'John',
                           last_name: 'Doe',
                           social_id: 'auth0|345678',
                           last_submission_date: two_hours_ago,
                           last_organization: prologschool,
                           last_exercise: more_clauses }

      it { expect(final.name).to eq 'John Doe' }
      it { expect(final.social_id).to eq 'auth0|345678' }

      it { expect(final.last_submission_date).to eq two_hours_ago }
      it { expect(final.last_organization).to eq prologschool }
      it { expect(final.last_exercise).to eq more_clauses }

      it { expect(final.permissions.as_json).to json_like student: 'prologschool/*' }
    end

    context 'when both have information, but original is newer' do
      before { original.transfer_progress_to! final }

      let(:original) { create :user,
                              permissions: {student: 'codeorga/*'},
                              first_name: 'johnny',
                              last_name: 'doe',
                              social_id: 'auth0|123456',
                              last_submission_date: two_hours_ago,
                              last_organization: codeorga,
                              last_exercise: your_first_program }
      let(:final) { create :user,
                           permissions: {student: 'prologschool/*'},
                           first_name: 'John',
                           last_name: 'Doe',
                           social_id: 'auth0|345678',
                           last_submission_date: 5.hours.ago,
                           last_organization: prologschool,
                           last_exercise: more_clauses }

      it { expect(final.name).to eq 'John Doe' }
      it { expect(final.social_id).to eq 'auth0|345678' }

      it { expect(final.last_submission_date).to eq two_hours_ago }
      it { expect(final.last_organization).to eq codeorga }
      it { expect(final.last_exercise).to eq your_first_program }

      it { expect(final.permissions.as_json).to json_like student: 'prologschool/*' }
    end
  end

  describe '#completed_containers_with_lookahead' do
    let(:student) { create :user }

    let(:organization) { Organization.current }

    let(:exercise_1) { create(:exercise) }
    let(:exercise_2) { create(:exercise) }

    let(:lesson_1) { create :lesson, exercises: [exercise_1] }
    let(:lesson_2) { create :lesson, exercises: [exercise_2] }

    context 'lookahead 0' do
      it { expect { student.completed_containers_with_lookahead([lesson_1, lesson_2], organization, lookahead: 0) }.to raise_error('invalid lookahead')  }
    end

    context 'no items completed' do
      it { expect(student.completed_containers_with_lookahead([lesson_1, lesson_2], organization)).to eq [lesson_1] }
    end

    context 'no items with lookahead 2' do
      it { expect(student.completed_containers_with_lookahead([lesson_1, lesson_2], organization, lookahead: 2)).to eq [lesson_1, lesson_2] }
    end
  end

  describe '#visit!' do
    let(:user) { build(:user) }

    before { user.visit! Organization.current }

    it { expect(user.last_organization).to eq Organization.current }
  end

  describe 'roles' do
    let(:other) { build(:organization, name: 'pdep') }
    let(:user) { build :user, permissions: {student: 'pdep/k2001', teacher: 'test/all'} }

    it { expect(user.student? 'test/all').to be true }
    it { expect(user.student? 'pdep/k2001').to be true }

    it { expect(user.teacher? 'test/all').to be true }
    it { expect(user.teacher? 'pdep/k2001').to be false }
  end

  describe '#submissions_count' do
    let!(:exercise_1) { build(:indexed_exercise) }
    let!(:exercise_2) { build(:indexed_exercise) }
    let!(:exercise_3) { build(:indexed_exercise) }

    let(:user) { create(:user) }
    context 'when there are no submissions' do
      it { expect(user.reload.last_submission_date).to be nil }
      it { expect(user.submitted_exercises_count).to eq 0 }
      it { expect(user.solved_exercises_count).to eq 0 }
      it { expect(user.submissions_count).to eq 0 }
      it { expect(user.passed_submissions_count).to eq 0 }
      it { expect(user.reload.last_exercise).to be_nil }
      it { expect(user.reload.last_guide).to be_nil }
    end

    context 'when there are passed submissions' do
      let!(:assignment_for) do
        exercise_1.submit_solution!(user, content: '')
        exercise_1.submit_solution!(user, content: '').passed!

        exercise_2.submit_solution!(user, content: '').passed!

        exercise_3.submit_solution!(user, content: '')
        exercise_3.submit_solution!(user, content: '')
      end

      it { expect(user.reload.last_submission_date).to be > Assignment.last.created_at }
      it { expect(user.submitted_exercises_count).to eq 3 }
      it { expect(user.solved_exercises_count).to eq 2 }
      it { expect(user.submissions_count).to eq 5 }
      it { expect(user.passed_submissions_count).to eq 2 }
      it { expect(user.reload.last_exercise).to eq exercise_3 }
      it { expect(user.reload.last_guide).to eq exercise_3.guide }

    end


    context 'when there are only failed submissions' do
      let!(:exercise_4) { build(:exercise) }

      let!(:assignment_for) do
        exercise_4.submit_solution!(user, content: '').failed!
      end

      it { expect(user.reload.last_exercise).to eq exercise_4 }
      it { expect(user.reload.last_guide).to eq exercise_4.guide }
    end
  end


  describe '.for_profile' do
    let(:user) { create(:user, first_name: 'some name', last_name: 'some last name') }
    let(:profile) { struct(uid: user.uid, first_name: nil, last_name: 'some other last name') }

    before { User.for_profile profile }

    it{ expect(User.find(user.id).first_name).to eq 'some name' }
    it{ expect(User.find(user.id).last_name).to eq 'some other last name' }

    describe 'notification' do
      let(:user) { build(:user) }

      context 'no changes' do
        before { expect_any_instance_of(Mumukit::Nuntius::NotificationMode::Deaf).to_not receive(:notify_event!) }
        it { User.for_profile profile }
      end

      context 'with changes' do
        before { expect_any_instance_of(Mumukit::Nuntius::NotificationMode::Deaf).to receive(:notify_event!).exactly(1).times }
        it { User.for_profile profile.to_h.merge(first_name: 'Mary').to_struct }
        it { User.for_profile profile.to_h.merge(last_name: 'Doe').to_struct }
      end

    end
  end

  describe '#accept_invitation!' do
    let(:student) { build :user }
    let(:course) { create(:course, slug: 'test/an-awesome-2019-course') }
    let(:invitation) { create :invitation, course: course  }
    before { student.accept_invitation! invitation }
    it { expect(student.student? 'test/an-awesome-2019-course').to be true }
    it { expect(student.student? 'foo/bar').to be false }
  end

  describe '#currently_in_exam?' do
    let(:student_not_in_exam) { build :user }
    let(:student_in_exam) { build :user }
    let(:exam) { create :exam }

    before { exam.authorize! student_in_exam }
    before { exam.authorize! student_not_in_exam }
    before { exam.start! student_in_exam }

    it { expect(student_not_in_exam.currently_in_exam?).to be false }
    it { expect(student_in_exam.currently_in_exam?).to be true }
  end

  describe '#discusser_of?' do
    let(:student) { create(:user, permissions: { student: 'test/*' }) }
    let(:teacher) { create(:user, permissions: { teacher: 'test/*' }) }

    context 'when organization has no forum minimal role' do
      it { expect(student.discusser_of?(Organization.current)).to be true }
      it { expect(teacher.discusser_of?(Organization.current)).to be true }
    end

    context 'when organization has a forum minimal role of student' do
      before { Organization.current.update! forum_discussions_minimal_role: 'student' }

      it { expect(student.discusser_of?(Organization.current)).to be true }
      it { expect(teacher.discusser_of?(Organization.current)).to be true }
    end

    context 'when organization has a forum minimal role of teacher' do
      before { Organization.current.update! forum_discussions_minimal_role: 'teacher' }

      it { expect(student.discusser_of?(Organization.current)).to be false }
      it { expect(teacher.discusser_of?(Organization.current)).to be true }
    end
  end

  describe '#can_discuss_in?' do
    let(:student) { create(:user, permissions: { student: 'test/*' }) }
    let(:teacher) { create(:user, permissions: { teacher: 'test/*' }) }
    let(:test_organization) { Organization.locate! 'test' }

    context 'when organization has no forum minimal role and forum not enabled' do
      it { expect(student.can_discuss_in?(test_organization)).to be false }
      it { expect(teacher.can_discuss_in?(test_organization)).to be false }
    end

    context 'when organization has forum enabled and not trusted requirements' do
      before { test_organization.forum_enabled = true }

      it { expect(student.can_discuss_in?(test_organization)).to be true }
      it { expect(teacher.can_discuss_in?(test_organization)).to be true }
    end

    context 'when organization has forum enabled and trusted requirements and user is not trusted' do
      before { test_organization.forum_enabled = true }
      before { test_organization.forum_only_for_trusted = true }

      it { expect(student.can_discuss_in?(test_organization)).to be false }
      it { expect(teacher.can_discuss_in?(test_organization)).to be false }
    end

    context 'when organization has forum enabled and trusted requirements and student is trusted' do
      before { test_organization.forum_enabled = true }
      before { test_organization.forum_only_for_trusted = true }
      before { student.trusted_for_forum = true }

      it { expect(student.can_discuss_in?(test_organization)).to be true }
      it { expect(teacher.can_discuss_in?(test_organization)).to be false }
    end
  end

  describe 'disabling' do
    let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }

    context 'enabled' do
      it { expect { user.ensure_enabled! }.to_not raise_error }
    end

    context 'disabled' do
      shared_context "disabled and buried user" do
        it { expect(user).to be_disabled }
        it { expect(user.accepts_reminders).to be false }
        it { expect(user.name).to eq 'shibi' }
        it { expect(user.email).to eq 'shibi@mumuki.org' }
        it { expect(user.gender).to be nil }
        it { expect(user.birthdate).to be nil }
        it { expect(user.reload.name).to eq 'shibi' }
        it { expect(user.disabled_at).to_not be nil }
        it { expect { user.ensure_enabled! }.to raise_error(Mumuki::Domain::DisabledError) }
      end

      describe '#disable!' do
        before { user.disable! }
        it_behaves_like "disabled and buried user"
      end

      describe '#destroy!' do
        before { user.destroy! }
        it_behaves_like "disabled and buried user"
      end

      describe '#destroy' do
        before { user.destroy }
        it_behaves_like "disabled and buried user"
      end
    end
  end
end
