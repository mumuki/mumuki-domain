require 'spec_helper'

describe ExamRegistration, organization_workspace: :test do
  describe '.authorization_criterion' do
    let(:registration) { create(:exam_registration, authorization_criterion_type: criterion_type, authorization_criterion_value: criterion_value) }

    context 'parse' do
      let(:criterion_value) { 75 }
      let(:criterion_type) { 'none' }
      context 'passing_criterion_type' do
        context 'passed_exercises criterion' do
          let(:criterion_type) { 'passed_exercises' }
          it { expect(registration.authorization_criterion).to be_an_instance_of ExamRegistration::AuthorizationCriterion::PassedExercises }
        end
        context 'none criterion' do
          let(:criterion_type) { 'none' }
          it { expect(registration.authorization_criterion).to be_an_instance_of ExamRegistration::AuthorizationCriterion::None }
        end
        context 'nil criterion' do
          let(:criterion_type) { nil }
          it { expect(registration.authorization_criterion).to be_an_instance_of ExamRegistration::AuthorizationCriterion::None }
        end
        context 'invalid criterion' do
          let(:criterion_type) { 'unsupported' }
          it { expect { registration.authorization_criterion }.to raise_error ArgumentError }
        end
      end
      context 'passing_criterion_value' do
        context 'with invalid passed_exercises' do
          let(:criterion_type) { 'passed_exercises' }
          let(:criterion_value) { -1 }
          it { expect { registration.authorization_criterion }.to raise_error("Invalid criterion value #{criterion_value} for #{criterion_type}") }
        end
      end
    end

    context 'enabled_for?' do
      let(:user) { create(:user) }
      let(:criterion_value) { 2 }

      context ExamRegistration::AuthorizationCriterion::None do
        let(:criterion_type) { 'none' }
        context 'with any user' do
          it { expect(registration.enabled_for? user).to be_truthy }
        end
      end

      context ExamRegistration::AuthorizationCriterion::PassedExercises do
        let(:criterion_type) { 'passed_exercises' }
        let(:exercises) { create_list(:indexed_exercise, 2) }
        let(:assignments_user) { exercises.map { |it| it.submit_solution!(user, content: '') } }

        context 'when count is greater or equal' do
          before { assignments_user.each(&:passed!) }
          it { expect(registration.enabled_for? user).to be_truthy }
        end

        context 'when count is less' do
          before { assignments_user.first.passed! }
          it { expect(registration.enabled_for? user).to be_falsey }
        end
      end
    end
  end
end
