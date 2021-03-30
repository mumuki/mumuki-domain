require 'spec_helper'

describe ExamRegistration, organization_workspace: :test do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:criterion_type) { :none }
  let(:criterion_value) { 0 }
  let(:registration) { create(:exam_registration, authorization_criterion_type: criterion_type, authorization_criterion_value: criterion_value) }

  def assignments_for(student, count)
    exercises = create_list(:indexed_exercise, count)
    exercises.map { |it| it.submit_solution!(student, content: '') }
  end

  describe '#authorization_request_for' do
    let(:request) { registration.authorization_request_for user }

    context "when the user doesn't have a request" do
      it { expect(request).to be_an_instance_of ExamAuthorizationRequest }
      it { expect(request.new_record?).to be_truthy }
      it { expect(request.organization).to eq registration.organization }
      it { expect(request.exam_registration).to eq registration }
    end

    context 'when the user has a request' do
      let!(:previous_request) { create(:exam_authorization_request, user: user, exam_registration: registration) }
      it { expect(request).to eq previous_request }
    end
  end

  describe '#register_users!' do
    context 'properly register all users' do
      before { registration.register_users!([user, other_user])}

      it { expect(registration.registrees).to eq([user, other_user]) }
    end
  end

  describe '#register!' do
    context 'properly register user' do
      before { registration.register! user }

      context 'when it was registered only once' do
        it { expect(registration.registrees.where(id: user.id).count).to eq(1) }
      end

      context 'when it was registered twice' do
        before { registration.register! user }

        it { expect(registration.registrees.where(id: user.id).count).to eq(1) }
      end
    end
  end

  describe '#notify_unnotified_registrees!' do
    context 'creates notifications for all registrees' do

      before do
        registration.register_users!([user, other_user])
        registration.notify_unnotified_registrees!
      end

      context 'registrees are properly notificated' do
        it { expect(user.notifications.count).to eq(1) }
        it { expect(other_user.notifications.count).to eq(1) }
        it { expect(registration.notifications.count).to eq(2) }
        it { expect(user.notifications.first.target).to eq(registration) }
      end

      context 'only new registrees are notified' do
        let(:yet_another_user) { create(:user) }

        before do
          registration.register! yet_another_user
          registration.notify_unnotified_registrees!
        end

        it { expect(user.notifications.count).to eq(1) }
        it { expect(other_user.notifications.count).to eq(1) }
        it { expect(yet_another_user.notifications.count).to eq(1) }
        it { expect(registration.notifications.count).to eq(3) }
      end
    end
  end

  describe '#process_requests!' do
    let(:criterion_type) { :passed_exercises }
    let(:criterion_value) { 2 }
    let(:exam) { create(:exam, exam_registrations: [registration]) }
    let!(:auth_requests) do
      [user, other_user].map { |it| create(:exam_authorization_request, exam_registration: registration, exam: exam, user: it) }
    end

    before { assignments_for(user, 3).each(&:passed!) }
    before { registration.process_requests! }

    context 'updates authorization request status' do
      it { expect(auth_requests[0].reload.status).to eq('approved') }
      it { expect(auth_requests[1].reload.status).to eq('rejected') }
    end

    context 'creates authorizations for approved users' do
      it { expect(exam.authorizations.size).to eq(1) }
      it { expect(exam.authorized? user).to be_truthy }
      it { expect(exam.authorized? other_user).to be_falsey }
    end

    context 'creates notifications for all users' do
      it { expect(user.notifications.size).to eq(1) }
      it { expect(other_user.notifications.size).to eq(1) }
      it { expect(user.notifications.first.target).to eq(auth_requests.first) }
    end
  end

  describe '#authorization_criterion' do
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

    context 'meets_authorization_criteria?' do
      let(:criterion_value) { 2 }
      let(:authorization_request) { create(:exam_authorization_request, exam_registration: registration, user: user) }

      context ExamRegistration::AuthorizationCriterion::None do
        let(:criterion_type) { 'none' }
        context 'with any user' do
          it { expect(registration.meets_authorization_criteria? authorization_request).to be_truthy }
        end
      end

      context ExamRegistration::AuthorizationCriterion::PassedExercises do
        let(:criterion_type) { 'passed_exercises' }
        let(:assignments) { assignments_for(user,2) }

        context 'when count is greater or equal' do
          before { assignments.each(&:passed!) }
          it { expect(registration.meets_authorization_criteria? authorization_request).to be_truthy }
        end

        context 'when count is less' do
          before { assignments.first.passed! }
          it { expect(registration.meets_authorization_criteria? authorization_request).to be_falsey }
        end
      end
    end
  end
end
