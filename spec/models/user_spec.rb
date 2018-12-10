require 'spec_helper'

describe User, organization_workspace: :test do
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

      before { original.reload.copy_progress_to! final }

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
      before { original.copy_progress_to! final.reload }

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
      before { original.copy_progress_to! final }

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
      before { original.copy_progress_to! final }

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
    let!(:exercise_1) { build(:exercise) }
    let!(:exercise_2) { build(:exercise) }
    let!(:exercise_3) { build(:exercise) }

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

  describe '#resubmit!' do
    let(:student) { create :user }
    let(:exercises) { FactoryBot.create_list(:exercise, 5) }

    let!(:chapter) {
      build(:chapter, lessons: [
        build(:lesson, exercises: exercises)]) }

    before { reindex_current_organization! }

    before { exercises.each { |it| it.submit_solution! student, content: '' } }

    it do
      student.assignments.each { |it| expect(it).to receive(:notify!).once }
      student.resubmit! Organization.current.name
    end
  end

  describe '#accept_invitation!' do
    let(:student) { build :user }
    let(:invitation) { build :invitation, course: build(:course) }
    before { student.accept_invitation! invitation }
    it { expect(student.student? invitation.course).to be true }
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
end
