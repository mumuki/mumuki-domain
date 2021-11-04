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

  describe '#verify_name!' do
    context 'when it has no verified name' do
      let(:user) { build(:user, first_name: 'Marie', last_name: 'Curie') }
      before { user.verify_name! }

      it { expect(user).to be_persisted }
      it { expect(user.verified_first_name).to eq 'Marie' }
      it { expect(user.verified_last_name).to eq 'Curie' }
    end

    context 'when it has a verified name' do
      let(:user) do
        build(:user,
          first_name: 'Mary',
          last_name: 'C',
          verified_first_name: 'Marie',
          verified_last_name: 'Curie')
      end

      context 'when verification is not forced' do
        before { user.verify_name! }

        it { expect(user).to be_persisted }
        it { expect(user.verified_first_name).to eq 'Marie' }
        it { expect(user.verified_last_name).to eq 'Curie' }
      end

      context 'when verification is forced' do
        before { user.verify_name! force: true }

        it { expect(user).to be_persisted }
        it { expect(user.verified_first_name).to eq 'Mary' }
        it { expect(user.verified_last_name).to eq 'C' }
      end
    end
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
                              permissions: { student: 'codeorga/*' },
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
                           permissions: { student: 'prologschool/*' },
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
                              permissions: { student: 'codeorga/*' },
                              first_name: 'johnny',
                              last_name: 'doe',
                              social_id: 'auth0|123456',
                              last_submission_date: 6.hours.ago,
                              last_organization: codeorga,
                              last_exercise: your_first_program }
      let(:final) { create :user,
                           permissions: { student: 'prologschool/*' },
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
                              permissions: { student: 'codeorga/*' },
                              first_name: 'johnny',
                              last_name: 'doe',
                              social_id: 'auth0|123456',
                              last_submission_date: two_hours_ago,
                              last_organization: codeorga,
                              last_exercise: your_first_program }
      let(:final) { create :user,
                           permissions: { student: 'prologschool/*' },
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

  describe 'immersive behaviour' do
    let(:student) { create :user }

    context 'when no granted organizations' do
      it { expect(student.immersive_organization_at nil).to be nil }
      it { expect(student.immersive_organizations_with_content_at nil).to be_empty }
      it { expect(student.current_immersive_context_at nil).to eq Organization.current }
      it { expect(student.current_immersive_context_and_content_at nil).to eq [Organization.current, nil] }
    end

    context 'when granted organizations' do
      let(:other_organization) { create :organization, immersive: immersive }

      context 'when student' do
        before { student.add_permission! :student, other_organization }

        context 'when granted organizations but not immersive' do
          let(:immersive) { false }

          it { expect(student.immersive_organizations_at nil).to be_empty }
          it { expect(student.immersive_organization_at nil).to be nil }
          it { expect(student.current_immersive_context_at nil).to eq Organization.current }
          it { expect(student.immersive_organizations_with_content_at nil).to be_empty }
          it { expect(student.current_immersive_context_and_content_at nil).to eq [Organization.current, nil] }
        end

        context 'when granted organizations and immersive' do
          let(:immersive) { true }

          it { expect(student.immersive_organizations_at nil).to eq [other_organization] }
          it { expect(student.immersive_organization_at nil).to eq other_organization }
          it { expect(student.current_immersive_context_at nil).to eq other_organization }
          it { expect(student.immersive_organizations_with_content_at nil).to eq [other_organization] }
          it { expect(student.current_immersive_context_and_content_at nil).to eq [other_organization, nil] }

          context 'when content is tested' do
            let(:exercise) { create(:exercise) }
            let!(:chapter) { create(:chapter, lessons: [create(:lesson, exercises: [exercise])]) }
            let(:assignment) { Assignment.new exercise: exercise, submitter: student }

            before { reindex_current_organization! }

            context 'when content is shared' do
              before do
                other_organization.update! book: Organization.current.book
                reindex_organization! other_organization
              end

              context 'with one organization' do
                it { expect(student.immersive_organization_at exercise).to eq other_organization }
                it { expect(student.immersive_organizations_with_content_at exercise).to eq [other_organization] }
                it { expect(student.current_immersive_context_and_content_at exercise).to eq [other_organization, exercise] }
                it { expect(assignment.current_notification_contexts).to eq [Organization.current, other_organization] }
              end

              context 'with many organizations' do
                let(:just_another_organization) { create :organization, name: 'just-another-one', immersive: true }
                before { student.add_permission! :student, just_another_organization }

                before do
                  just_another_organization.update! book: Organization.current.book
                  reindex_organization! just_another_organization
                end

                it { expect(student.immersive_organization_at exercise).to be_nil }
                it { expect(student.immersive_organizations_with_content_at exercise).to eq [other_organization, just_another_organization] }
                it { expect(student.current_immersive_context_and_content_at exercise).to eq [Organization.current, exercise] }
                it { expect(assignment.current_notification_contexts).to eq [Organization.current] }
              end
            end

            context 'when content inside container is shared' do
              let(:guide) { create(:guide) }
              let(:lesson_immersive) { create(:lesson, guide: guide) }
              let(:lesson_immersible) { create(:lesson, guide: guide) }
              let!(:chapter) { create(:chapter, lessons: [lesson_immersible]) }
              let!(:chapter_immersive) { create(:chapter, lessons: [lesson_immersive]) }

              before do
                other_organization.book.update! chapters: [chapter_immersive]
                reindex_organization! other_organization
              end

              it { expect(student.immersive_organizations_with_content_at lesson_immersible).to eq [other_organization] }
              it { expect(student.current_immersive_context_and_content_at(lesson_immersible)).to eq [other_organization, lesson_immersive] }
            end

            context 'when content is not shared' do
              it { expect(student.immersive_organization_at exercise).to be nil }
              it { expect(student.immersive_organizations_with_content_at exercise).to eq [other_organization] }
              it { expect(student.current_immersive_context_and_content_at exercise).to eq [other_organization, nil] }
              it { expect(assignment.current_notification_contexts).to eq [Organization.current] }
            end
          end
        end
      end

      context 'when teacher and immersive' do
        before { student.add_permission! :teacher, other_organization }
        let(:immersive) { true }

        it { expect(student.immersive_organization_at nil).to eq nil }
        it { expect(student.current_immersive_context_at nil).to eq Organization.current }
      end
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
      it { expect { student.completed_containers_with_lookahead([lesson_1, lesson_2], organization, lookahead: 0) }.to raise_error('invalid lookahead') }
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
    let(:user) { build :user, permissions: { student: 'pdep/k2001', teacher: 'test/all' } }

    it { expect(user.student? 'test/all').to be true }
    it { expect(user.student? 'pdep/k2001').to be true }

    it { expect(user.teacher? 'test/all').to be true }
    it { expect(user.teacher? 'pdep/k2001').to be false }
  end

  describe '#passed_submissions_count_in' do
    let!(:exercise_1) { build(:indexed_exercise) }
    let!(:exercise_2) { build(:indexed_exercise) }
    let!(:exercise_3) { build(:indexed_exercise) }

    let(:user) { create(:user) }

    let!(:assignment_for) do
      # Failing after passing shouldn't affect count
      exercise_1.submit_solution!(user, content: '').passed!
      exercise_1.submit_solution!(user, content: '').failed!

      exercise_2.submit_solution!(user, content: '').passed!
    end

    context 'an organization with submissions' do
      it { expect(user.passed_submissions_count_in Organization.current).to eq 2 }
    end

    context 'an organization without submissions' do
      let(:another_organization) { create(:organization) }
      it { expect(user.passed_submissions_count_in another_organization).to eq 0 }
    end
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

  describe '.notify_permissions_changed!' do
    let(:user) { build(:user) }

    context 'with no changes at all' do
      before { expect_any_instance_of(Mumukit::Nuntius::NotificationMode::Deaf).to_not receive(:notify!) }
      it { user.save_and_notify! }
    end

    context 'with name changes' do
      before { expect_any_instance_of(Mumukit::Nuntius::NotificationMode::Deaf).to_not receive(:notify!) }
      it { user.update_and_notify!(first_name: 'Mary', last_name: 'Doe') }
    end

    context 'with permission changes' do
      let(:permissions_diff) { {
        user: {
          uid: user.uid,
          old_permissions: {},
          new_permissions: { student: 'example/foo' }.as_json
        }
      } }

      context 'using update_and_notify!' do
        before { expect_any_instance_of(Mumukit::Nuntius::NotificationMode::Deaf).to receive(:notify!).with('user-permissions-changed', permissions_diff) }
        it { user.update_and_notify!(permissions: { student: 'example/foo' }) }
      end

      context 'using save_and_notify!' do
        before { expect_any_instance_of(Mumukit::Nuntius::NotificationMode::Deaf).to receive(:notify!).with('user-permissions-changed', permissions_diff) }
        it { user.add_permission! :student, 'example/foo'; user.save_and_notify! }
      end
    end

  end

  describe '.for_profile' do
    let(:user) { create(:user, first_name: 'some name', last_name: 'some last name') }
    let(:profile) { struct(uid: user.uid, first_name: nil, last_name: 'some other last name') }

    before { User.for_profile profile }

    it { expect(User.find(user.id).first_name).to eq 'some name' }
    it { expect(User.find(user.id).last_name).to eq 'some other last name' }

  end

  describe '#accept_invitation!' do
    let(:student) { build :user }
    let(:course) { create(:course, slug: 'test/an-awesome-2019-course') }
    let(:invitation) { create :invitation, course: course }
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

  describe '#can_access_teacher_info_in?' do
    let(:student) { create(:user, permissions: { student: 'test/*' }) }
    let(:teacher) { create(:user, permissions: { teacher: 'test/*' }) }
    let(:test_organization) { Organization.locate! 'test' }

    context 'when organization is not a teacher training' do
      it { expect(student.can_access_teacher_info_in?(test_organization)).to be false }
      it { expect(teacher.can_access_teacher_info_in?(test_organization)).to be true }
    end

    context 'when organization is a teacher training everyone can see teacher_info' do
      before { test_organization.teacher_training = true }

      it { expect(student.can_access_teacher_info_in?(test_organization)).to be true }
      it { expect(teacher.can_access_teacher_info_in?(test_organization)).to be true }
    end
  end

  describe '#name_initials' do
    context 'with first_name and last_name' do
      let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }

      it { expect(user.name_initials).to eq 'J D' }
    end

    context 'with just first_name' do
      let(:user) { create(:user, first_name: 'John', last_name: nil) }

      it { expect(user.name_initials).to eq 'J' }
    end

    context 'with just last_name' do
      let(:user) { create(:user, first_name: nil, last_name: 'Doe') }

      it { expect(user.name_initials).to eq 'D' }
    end

    context 'with no first_name or last_name' do
      let(:user) { create(:user, first_name: nil, last_name: nil) }

      it { expect(user.name_initials).to eq '' }
    end

    describe '#abbreviated_name' do
      context 'with first_name and last_name' do
        let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }

        it { expect(user.abbreviated_name).to eq 'John D.' }
      end

      context 'with just first_name' do
        let(:user) { create(:user, first_name: 'John', last_name: nil) }

        it { expect(user.abbreviated_name).to eq 'John' }
      end

      context 'with just last_name' do
        let(:user) { create(:user, first_name: nil, last_name: 'Doe') }

        it { expect(user.abbreviated_name).to eq 'D.' }
      end

      context 'with no first_name or last_name' do
        let(:user) { create(:user, first_name: nil, last_name: nil) }

        it { expect(user.abbreviated_name).to eq '' }
      end

      context 'with several names' do
        let(:user) { create(:user, first_name: 'John George', last_name: 'Doe Foo') }

        it { expect(user.abbreviated_name).to eq 'John George D.' }
      end
    end

    context 'with several names' do
      let(:user) { create(:user, first_name: 'John George', last_name: 'Doe Foo') }

      it { expect(user.name_initials).to eq 'J G D F' }
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

  describe '#age' do
    let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }
    before do
      mocked_time = Time.parse('2020-12-08')
      allow(Time).to receive(:now).and_return(mocked_time)
    end

    context 'with no birthdate' do
      before { user.birthdate = nil }
      it { expect(user.age).to eq nil }
    end

    context 'with birthdate' do
      context 'in a leap year and the same month and day' do
        before { user.birthdate = '2000-12-08' }
        it { expect(user.age).to eq 20 }
      end

      context 'in a leap year one day before birthday' do
        before { user.birthdate = '2000-12-07' }
        it { expect(user.age).to eq 20 }
      end

      context 'in a leap year one day after birthday' do
        before { user.birthdate = '2000-12-09' }
        it { expect(user.age).to eq 19 }
      end

      context 'in a non-leap year and the same month and day' do
        before { user.birthdate = '2002-12-08' }
        it { expect(user.age).to eq 18 }
      end

      context 'in a non-leap year one day before birthday' do
        before { user.birthdate = '2002-12-07' }
        it { expect(user.age).to eq 18 }
      end

      context 'in a non-leap year one day after birthday' do
        before { user.birthdate = '2002-12-09' }
        it { expect(user.age).to eq 17 }
      end
    end
  end

  describe 'formal name' do
    context 'user has no verified name' do
      let(:user) { create :user, first_name: 'foo', last_name: 'bar' }

      it { expect(user.formal_first_name).to eq 'foo' }
      it { expect(user.formal_last_name).to eq 'bar' }
    end
    context 'user has verified name' do
      let(:user) { create :user, first_name: 'foo', last_name: 'bar', verified_first_name: 'Joe', verified_last_name: 'Doe' }

      it { expect(user.formal_first_name).to eq 'Joe' }
      it { expect(user.formal_last_name).to eq 'Doe' }
    end
    context 'user has verified last name but not verified first name' do
      let(:user) { create :user, first_name: 'foo', last_name: 'bar', verified_last_name: 'Doe' }

      it { expect(user.formal_first_name).to eq 'foo' }
      it { expect(user.formal_last_name).to eq 'Doe' }
    end
  end

  describe '#certificated_in?' do
    let(:user) { create :user, uid: 'test' }
    let(:certificate_program_1) { create(:certificate_program, certificates: [certificate_1])}
    let(:certificate_program_2) { create(:certificate_program, certificates: [certificate_2])}
    let(:certificate_1) { create :certificate, user: user }
    let(:certificate_2) { create :certificate, user: create(:user) }

    it { expect(user.certificated_in? certificate_program_1).to eq true }
    it { expect(user.certificated_in? certificate_program_2).to eq false }
  end

  describe '#certificates_in_organization' do
    let!(:user_1) { create :user, uid: 'test_1' }
    let!(:user_2) { create :user, uid: 'test_2' }

    let!(:certificate_1) { create :certificate, user: user_1 }
    let!(:certificate_2) { create :certificate, user: user_2 }
    let!(:certificate_3) { create :certificate, user: user_1 }
    let!(:certificate_4) { create :certificate, user: user_1, organization: create(:organization) }

    it { expect(user_1.certificates_in_organization Organization.current).to contain_exactly certificate_1, certificate_3 }
  end

  describe 'delete_account_token' do
    describe '#generate_delete_account_token!' do
      let(:user) { create :user }
      before { user.generate_delete_account_token! }

      it { expect(user.delete_account_token).to be_an_instance_of(String) }
      it { expect(user.delete_account_token).to have_attributes(size: be > 10) }
      it { expect(user.delete_account_token_expiration_date).to be_between(Time.current, 2.hours.since) }
    end

    describe '#delete_account_token_matches?' do
      let(:expiration_date) { 2.days.from_now }
      let(:user) { create :user, delete_account_token: 'secret333', delete_account_token_expiration_date: expiration_date }

      context 'valid token' do
        it { expect(user.delete_account_token_matches? 'secret333').to be_truthy }
      end

      context 'no token' do
        before { user.update! delete_account_token: nil }
        it { expect(user.delete_account_token_matches? nil).to be_falsey }
      end

      context 'invalid token' do
        it { expect(user.delete_account_token_matches? 'badtoken').to be_falsey }
      end

      context 'expired token' do
        let(:expiration_date) { 1.hour.ago }
        it { expect(user.delete_account_token_matches? 'secret333').to be_falsey }
      end

      context 'token with no expiration date' do
        let(:expiration_date) { nil }
        it { expect(user.delete_account_token_matches? 'secret333').to be_falsey }
      end
    end
  end

  describe '#clear_progress_for!' do
    let(:user) { create :user }

    let(:organization_1) { create :organization, name: 'orga-1' }
    let(:organization_2) { create :organization, name: 'orga-2' }
    let(:exercise_1) { create :indexed_exercise }
    let(:exercise_2) { create :indexed_exercise }

    let(:messages_count) { Message.count }

    before do
      organization_1.switch!
      assignment_1 = exercise_1.submit_solution!(user).tap(&:passed!)
      create :message, sender: user, assignment: assignment_1
      organization_2.switch!
      assignment_2 = exercise_2.submit_solution!(user).tap(&:passed!)
      create :message, sender: user, assignment: assignment_2
      create :message, sender: user, discussion_id: 1
    end

    it { expect(user.assignments.count).to eq 2 }
    it { expect(user.indicators.count).to eq 6 }
    it { expect(user.user_stats.count).to eq 2 }
    it { expect(messages_count).to eq 3 }

    context 'on clearing progress for a specific organization' do
      before { user.clear_progress_for!(organization_1) }

      it { expect(user.assignments.count).to eq 1 }
      it { expect(user.indicators.count).to eq 3 }
      it { expect(user.user_stats.count).to eq 1 }
      it { expect(messages_count).to eq 2 }
    end

    context 'on general progress clear' do
      before { user.clear_progress_for!(nil) }

      it { expect(user.assignments.count).to eq 0 }
      it { expect(user.indicators.count).to eq 0 }
      it { expect(user.user_stats.count).to eq 0 }
      it { expect(messages_count).to eq 1 }
    end
  end

  describe '#ignores_notification?' do
    let(:user) { create(:user, ignored_notifications: ignored_notifications) }

    let(:notification) { create(:notification, user: user, subject: :custom) }

    context 'when user ignores notification type' do
      let(:ignored_notifications) { ['custom'] }

      it { expect(user.ignores_notification? notification).to be true }
    end

    context 'when user does not ignore notification type' do
      let(:ignored_notifications) { ['exam_registration'] }

      it { expect(user.ignores_notification? notification).to be false }
    end
  end

  describe '#notifications_in_organization' do
    let(:user) { create(:user) }
    let(:organization) { create(:organization) }
    let!(:notification1) { create(:notification, user: user, organization: organization) }
    let!(:notification2) { create(:notification, user: user) }

    let(:notifications_in_organization) { user.notifications_in_organization(organization) }

    it { expect(user.notifications.count).to eq 2 }
    it { expect(notifications_in_organization.count).to eq 1 }
    it { expect(notifications_in_organization).to eq [notification1] }
  end

  describe '#solved_any_exercises?' do
    let(:user) { build :user, permissions: { student: 'test/all' }}
    let(:ex_orga) { create :organization, name: 'ex' }
    let(:test_orga) { Organization.locate!('test') }

    before do
      ex_orga.switch!
      build(:indexed_exercise).submit_solution!(user, content: '').passed!
    end

    it { expect(user.solved_any_exercises?(test_orga)).to eql false }
    it { expect(user.solved_any_exercises?(ex_orga)).to eql true }
    it { expect(user.solved_any_exercises?).to eql true }
  end

  describe '#detach!' do
    let(:user) { build :user, permissions: { student: 'test/all:ex/all' }}
    let(:ex_orga) { create :organization, name: 'ex' }
    let(:course) { create :course, organization: ex_orga, slug: 'ex/all'}
    let(:test_orga) { Organization.locate!('test') }

    context 'removes student permission without add ex student of ex orga because user has no exercises solved' do
      before { user.detach! :student, course }

      it { expect(user.student_of?(ex_orga)).to be_falsey }
      it { expect(user.ex_student_of?(ex_orga)).to be_falsey }
      it { expect(user.student_of?(test_orga)).to be_truthy }
    end

    context 'becomes ex student of ex orga because user has exercises solved' do
      before { ex_orga.switch! }
      before { build(:indexed_exercise).submit_solution!(user, content: '').passed! }
      before { user.detach! :student, course }

      it { expect(user.student_of?(ex_orga)).to be_falsey }
      it { expect(user.ex_student_of?(ex_orga)).to be_truthy }
      it { expect(user.student_of?(test_orga)).to be_truthy }
    end

    context 'removes student permission without add ex student of ex orga because user has exercises solved but avoid make_ex_student' do
      before { ex_orga.switch! }
      before { build(:indexed_exercise).submit_solution!(user, content: '').passed! }
      before { user.detach! :student, course, deep: true }

      it { expect(user.student_of?(ex_orga)).to be_falsey }
      it { expect(user.ex_student_of?(ex_orga)).to be_falsey }
      it { expect(user.student_of?(test_orga)).to be_truthy }
    end
  end
end
