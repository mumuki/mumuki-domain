require 'spec_helper'

describe Gamified, organization_workspace: :test do

  def award_experience_points!(assignment, status)
    assignment.status = status
    assignment.award_experience_points!
    assignment.update_top_submission!
  end

  let(:student) { create(:user) }
  let(:exercise) { create(:indexed_exercise) }
  let(:assignment) { create(:assignment, submitter: student, exercise: exercise)}
  let(:experience_points) { assignment.user_stats_for(student, Organization.current) }

  describe '#award_experience_points!' do
    context 'no passed exercises' do
      it 'has no experience points for that user' do
        expect(experience_points.exp).to eq 0
      end
    end

    context 'one passed exercise' do
      it 'does not award points for a failed exercise' do
        award_experience_points!(assignment, :failed)

        expect(experience_points.exp).to eq 0
      end

      it 'awards points for a passed with warnings exercise' do
        award_experience_points!(assignment, :passed_with_warnings)

        expect(experience_points.exp).to eq Mumuki::Domain::Status::Submission::PassedWithWarnings.exp_given
      end

      it 'awards points for a passed exercise' do
        award_experience_points!(assignment, :passed)

        expect(experience_points.exp).to eq Mumuki::Domain::Status::Submission::Passed.exp_given
      end

      it 'awards max points once even if passed multiple times' do
        award_experience_points!(assignment, :passed)
        award_experience_points!(assignment, :passed)
        award_experience_points!(assignment, :passed)

        expect(experience_points.exp).to eq Mumuki::Domain::Status::Submission::Passed.exp_given
      end

      it 'awards max points once even if gradually improved' do
        award_experience_points!(assignment, :failed)
        award_experience_points!(assignment, :passed_with_warnings)
        award_experience_points!(assignment, :passed)

        expect(experience_points.exp).to eq Mumuki::Domain::Status::Submission::Passed.exp_given
      end

      it 'does not take points away even if failed after passing' do
        award_experience_points!(assignment, :passed)
        award_experience_points!(assignment, :failed)

        expect(experience_points.exp).to eq Mumuki::Domain::Status::Submission::Passed.exp_given
      end

      it 'does not take points away even if errored after passing with warnings' do
        award_experience_points!(assignment, :passed_with_warnings)
        award_experience_points!(assignment, :errored)

        expect(experience_points.exp).to eq Mumuki::Domain::Status::Submission::PassedWithWarnings.exp_given
      end
    end

    context 'many passed exercises' do
      let(:another_exercise) { create(:indexed_exercise) }
      let(:another_assignment) { create(:assignment, submitter: student, exercise: exercise)}
      let(:one_more_exercise) { create(:indexed_exercise) }
      let(:one_more_assignment) { create(:assignment, submitter: student, exercise: exercise)}

      before do
        award_experience_points!(assignment, :passed)
        award_experience_points!(another_assignment, :passed)
        award_experience_points!(one_more_assignment, :passed)
      end

      it 'adds up experience' do
        expect(experience_points.exp).to eq Mumuki::Domain::Status::Submission::Passed.exp_given * 3
      end
    end
  end
end
