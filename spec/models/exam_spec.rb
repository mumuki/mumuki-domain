require 'spec_helper'

describe Exam, organization_workspace: :test do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:course) { create(:course, slug: 'test/foo') }

  describe '#upsert' do
    let(:guide) { create(:guide) }
    let(:exam_json) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: 150, language: 'haskell', name: 'foo', uids: [], organization: 'test', course: course.slug, passing_criterion: {type: 'none'}} }
    let!(:exam) { Exam.import_from_resource_h! exam_json }
    context 'when new exam and the guide is the same' do
      let(:guide2) { create(:guide) }
      let(:exam_json2) { {eid: '2', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: 150, language: 'haskell', name: 'foo', uids: [], organization: 'test', course: course.slug, passing_criterion: {type: 'percentage', value: 75}} }
      let!(:exam2) { Exam.import_from_resource_h! exam_json2 }
      context 'and the organization is the same' do
        it { expect(Exam.count).to eq 1 }
        it { expect(Usage.where(item: guide, parent_item: exam).count).to eq 0 }
        it { expect(Usage.where(item: guide, parent_item: exam2).count).to eq 1 }
        it { expect(exam2.passing_criterion_type).to eq 'percentage' }
        it { expect(exam2.passing_criterion_value).to eq 75 }
        it { expect(ExamAuthorization.where(exam: exam).count).to eq 0 }
      end
    end

  end

  describe '#validate_accessible_for!' do
    context 'not enabled' do
      let(:exam) { create(:exam, start_time: 5.minutes.since, end_time: 10.minutes.since, course: course) }

      it { expect(exam.enabled?).to be false }

      context 'not authorized' do
        it { expect { exam.validate_accessible_for! user }.to raise_error(Mumuki::Domain::ForbiddenError) }
      end

      context 'authorized' do
        it { expect(exam.enabled?).to be false }
      end
    end

    context 'enabled' do
      let(:exam) { create(:exam, start_time: 5.minutes.ago, end_time: 10.minutes.since, course: course) }

      it { expect(exam.enabled?).to be true }

      context 'not authorized' do
        it { expect { exam.validate_accessible_for! user }.to raise_error(Mumuki::Domain::ForbiddenError) }
      end

      context 'authorized' do
        before { exam.authorize! user }

        it { expect { exam.validate_accessible_for! user }.to_not raise_error }
        it { expect { exam.validate_accessible_for! other_user }.to raise_error(Mumuki::Domain::ForbiddenError) }
      end

      context 'import_from_json' do
        let(:user) { create(:user, uid: 'auth0|1') }
        let(:user2) { create(:user, uid: 'auth0|2') }
        let(:guide) { create(:guide) }
        let(:duration) { 150 }
        let(:exam_json) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: duration, language: 'haskell', name: 'foo', uids: [user.uid], organization: 'test', course: course.slug, passing_criterion_type: 'none'} }
        before { Exam.import_from_resource_h! exam_json }

        context 'new exam' do
          it { expect(Exam.count).to eq 1 }
          it { expect { Exam.find_by(classroom_id: '1').validate_accessible_for! user }.to_not raise_error }
          it { expect(Usage.where(organization: Organization.current, item: guide).count).to eq 1 }
          it { expect(guide.usage_in_organization).to be_a Exam }
        end

        context 'new exam, no duration' do
          let(:duration) { nil }
          it { expect(guide.usage_in_organization).to be_a Exam }
        end

        context 'existing exam' do
          let(:exam_json2) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: 150, language: 'haskell', name: 'foo', uids: [user2.uid], organization: 'test', course: course.slug, passing_criterion_type: 'none'} }
          before { Exam.import_from_resource_h! exam_json2 }

          it { expect(Exam.count).to eq 1 }
          it { expect(Usage.where(organization: Organization.current, item: guide).count).to eq 1 }
          it { expect { Exam.find_by(classroom_id: '1').validate_accessible_for! user }.to raise_error(Mumuki::Domain::ForbiddenError) }
          it { expect { Exam.find_by(classroom_id: '1').validate_accessible_for! user2 }.to_not raise_error }
          it { expect { Exam.last.passing_criterion }.to_not raise_error }

        end
      end

      context 'real_end_time' do
        let(:user) { create(:user, uid: 'auth0|1') }
        let(:guide) { create(:guide) }
        let(:exam_json) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: duration, language: 'haskell', name: 'foo', uids: [user.uid], organization: 'test', course: course.slug, passing_criterion_type: 'none'} }
        let(:exam) { Exam.import_from_resource_h! exam_json }
        before { exam.start! user }

        context 'with duration' do
          let(:duration) { 150 }
          it { expect(exam.real_end_time user).to eq(exam.end_time) }
          it { expect(exam.started? user).to be_truthy }
        end

        context 'with short duration' do
          let(:duration) { 3 }
          it { expect(exam.real_end_time user).to eq(exam.started_at(user) + 3.minutes) }
          it { expect(exam.started? user).to be_truthy }
        end

        context 'no duration' do
          let(:duration) { nil }
          it { expect(exam.real_end_time user).to eq(exam.end_time) }
          it { expect(exam.started? user).to be_truthy }
        end
      end

      context 'update exam does not change user started_at' do
        let(:user) { create(:user, uid: 'auth0|1') }
        let(:guide) { create(:guide) }
        let(:exam_json) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: 150, language: 'haskell', name: 'foo', uids: [user.uid], organization: 'test', course: course.slug, passing_criterion_type: 'none'} }
        let(:exam) { Exam.import_from_resource_h! exam_json }
        before { exam.start! user }
        before { Exam.import_from_resource_h! exam_json.merge(organization: 'test') }

        it { expect(exam.started?(user)).to be true }

      end

      context 'create exam with non existing user' do
        let(:guide) { create(:guide) }
        let(:exam_json) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: 150, language: 'haskell', name: 'foo', uids: [user.uid], organization: 'test', course: course.slug, passing_criterion_type: 'none'} }
        let(:exam) { Exam.import_from_resource_h! exam_json }

        it { expect { Exam.import_from_resource_h! exam_json.merge(organization: 'test') }.not_to raise_error }

      end

      context '.passing_criterion' do
        let(:criterion_value) { 75 }
        let(:criterion_type) { 'none' }
        let(:exam) { create(:exam, passing_criterion_type: criterion_type, passing_criterion_value: criterion_value) }
        context 'passing_criterion_type' do
          context 'percentage criterion' do
            let(:criterion_type) { 'percentage' }
            it { expect(exam.passing_criterion).to be_an_instance_of Exam::PassingCriterion::Percentage }
          end
          context 'passed_exercises criterion' do
            let(:criterion_type) { 'passed_exercises' }
            it { expect(exam.passing_criterion).to be_an_instance_of Exam::PassingCriterion::PassedExercises }
          end
          context 'none criterion' do
            let(:criterion_type) { 'none' }
            it { expect(exam.passing_criterion).to be_an_instance_of Exam::PassingCriterion::None }
          end
          context 'nil criterion' do
            let(:criterion_type) { nil }
            it { expect(exam.passing_criterion).to be_an_instance_of Exam::PassingCriterion::None }
          end
          context 'invalid criterion' do
            let(:criterion_type) { 'unsupported' }
            it { expect { exam.passing_criterion }.to raise_error ArgumentError }
          end
        end
        context 'passing_criterion_value' do
          context 'with invalid percentage' do
            let(:criterion_type) { 'percentage'}
            let(:criterion_value) { 101 }
            it { expect { exam.passing_criterion }.to raise_error("Invalid criterion value #{criterion_value} for #{criterion_type}") }
          end
          context 'with invalid passed_exercises' do
            let(:criterion_type) { 'passed_exercises'}
            let(:criterion_value) { -1 }
            it { expect { exam.passing_criterion }.to raise_error("Invalid criterion value #{criterion_value} for #{criterion_type}") }
          end
        end
      end


      context 'unauthorized user does not start' do
        let(:exam) { create(:exam) }
        it { expect { exam.start! user }.to raise_error Mumuki::Domain::ForbiddenError }
      end

      context 'teacher does not start exams' do
        let(:teacher) { create(:user, uid: 'auth0|1') }
        let(:guide) { create(:guide) }
        let(:exam_json) { {eid: '1', slug: guide.slug, start_time: 5.minutes.ago, end_time: 10.minutes.since, duration: 150, language: 'haskell', name: 'foo', uids: [], organization: 'test', course: course.slug, passing_criterion_type: 'none'} }
        let(:exam) { Exam.import_from_resource_h! exam_json }

        context 'exam_authorization do not receive start method' do
          before { expect(teacher).to receive(:teacher_here?).and_return(true) }
          before { expect_any_instance_of(ExamAuthorization).to_not receive(:start!) }
          it { expect { exam.start!(teacher) }.to_not raise_error }

        end

        context 'exam is not started by a teacher' do
          it { expect(exam.started?(teacher)).to be_falsey }
        end

      end
    end
  end
end
