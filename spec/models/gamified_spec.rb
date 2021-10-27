require 'spec_helper'

describe Gamified, organization_workspace: :test do
  let(:student) { create(:user) }
  let(:exercise) { create(:indexed_exercise) }
  let(:assignment) { create(:assignment, submitter: student, exercise: exercise)}
  let(:exp) { UserStats.exp_for(student) }

  let(:evaluation) { double Mumuki::Domain::Evaluation::Automated }

  before do
    allow(Mumuki::Domain::Evaluation::Automated).to receive(:new).and_return(evaluation)
  end

  def submit_on!(exercise, status)
    allow(evaluation).to receive(:evaluate!).and_return({ status: status })
    exercise.submit_solution!(student)
  end

  describe '#award_experience_points!' do
    context 'no solutions sent' do
      it 'has no experience points for that user' do
        expect(exp).to eq 0
      end
    end

    context 'solutions sent on one exercise' do
      context 'failed' do
        before { submit_on!(exercise, :failed) }

        it 'does not award points' do
          expect(exp).to eq 0
        end
      end

      context 'passed_with_warnings' do
        before { submit_on!(exercise, :passed_with_warnings) }

        it 'awards points' do
          expect(exp).to eq Mumuki::Domain::Status::Submission::PassedWithWarnings.exp_given
        end

        it 'does not take points away if errored afterwards' do
          submit_on!(exercise, :errored)

          expect(exp).to eq Mumuki::Domain::Status::Submission::PassedWithWarnings.exp_given
        end
      end

      context 'passed' do
        before { submit_on!(exercise, :passed) }

        it 'awards points if passed once' do
          expect(exp).to eq Mumuki::Domain::Status::Submission::Passed.exp_given
        end

        it 'awards same amount of points if passed multiple times' do
          3.times { submit_on!(exercise, :passed) }

          expect(exp).to eq Mumuki::Domain::Status::Submission::Passed.exp_given
        end

        it 'does not take points away if failed afterwards' do
          submit_on!(exercise, :failed)

          expect(exp).to eq Mumuki::Domain::Status::Submission::Passed.exp_given
        end
      end

      context 'gradually improving' do
        before do
          submit_on!(exercise, :failed)
          submit_on!(exercise, :passed_with_warnings)
          submit_on!(exercise, :passed)
        end

        it 'awards max points once' do
          expect(exp).to eq Mumuki::Domain::Status::Submission::Passed.exp_given
        end
      end
    end

    context 'solutions sent on many exercises' do
      let(:another_exercise) { create(:indexed_exercise) }
      let(:one_more_exercise) { create(:indexed_exercise) }

      before do
        submit_on!(exercise, :passed)
        submit_on!(another_exercise, :passed)
        submit_on!(one_more_exercise, :passed)
      end

      it 'adds up experience' do
        expect(exp).to eq Mumuki::Domain::Status::Submission::Passed.exp_given * 3
      end
    end

    context 'during an exam' do
      let(:exam) { create(:exam, start_time: 5.minutes.ago, end_time: 10.minutes.since, course: create(:course, slug: 'test/foo')) }

      before do
        exam.authorize! student
        exam.start! student
        submit_on!(exercise, :passed)
      end

      it 'does not award points' do
        expect(exp).to eq 0
      end
    end
  end
end
