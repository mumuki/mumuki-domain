require 'spec_helper'

describe Mumuki::Domain::Incognito do
  let(:user) { Mumuki::Domain::Incognito }
  let(:organization) { create(:organization) }

  it 'can mock an AR relation' do
    Assignment.new submitter: user
  end

  describe 'ensure_enabled!' do
    it { expect { user.ensure_enabled! }.to_not raise_error }
  end

  describe 'assignment fooling' do
    let(:assignment) { user.build_assignment(exercise, organization) }

    context 'when exercise has no default content' do
      let(:exercise) { create(:exercise) }

      it { expect(assignment).to be_an Assignment }
      it { expect(assignment.submitter).to be user }
      it { expect(assignment.current_content).to eq '' }
    end

    context 'when exercise has default content' do
      let(:exercise) { create(:exercise, default_content: '...') }

      it { expect(assignment.current_content).to eq '...' }
    end
  end

  describe 'guide fooling' do
    let(:guide) { create(:guide, exercises: [ create(:exercise), create(:exercise) ]) }

    describe 'completion_percentage_for', organization_workspace: :test do
      it { expect(guide.completion_percentage_for(user)).to eq 0 }
    end

    describe 'next_exercise', organization_workspace: :test do
      # TODO this looks weird. Why do we need a non-polymorphic
      # next_exercise? Aren't indicators not enought?
      it { expect(guide.next_exercise(user)).to eq guide.exercises.first }
    end
  end

  describe 'exercise fooling' do
    let(:problem) { create(:problem) }

    describe 'next_for' do
      it { expect(problem.next_for(user)).to be nil }
    end

    describe 'try_submit_solution!', organization_workspace: :test do
      let!(:chapter) do
        create(:chapter, name: 'Functional Programming', lessons: [
          create(:lesson, exercises: [problem])
        ])
      end
      let(:bridge_response) { {result: '0 failures', status: :passed} }

      before { reindex_current_organization! }
      before { expect_any_instance_of(Language).to receive(:run_tests!).and_return(bridge_response) }

      let!(:assignment) { problem.try_submit_solution!(user) }

      it { expect(assignment).to_not be nil }
      it { expect(assignment.status).to be_like :passed }
    end
  end

  describe 'immersive context fooling' do
    context 'no immersive organizations' do
      it { expect(user.immersive_organizations_at(nil)).to be_empty }
    end

    context 'no current immersive context' do
      it { expect(user.current_immersive_context_at(nil)).to be_nil }
    end
  end

  describe 'terms context fooling' do
    let!(:legal_term) { create(:term, scope: :legal, locale: :en) }
    let!(:moderator_term) { create(:term, scope: :moderator, locale: :en) }

    context 'no role terms to accept' do
      it { expect(user.has_role_terms_to_accept?).to eq false }
    end

    context 'has_accepted? term' do
      it { expect(user.has_accepted?(legal_term)).to eq false }
    end

    context 'profile_terms' do
      it { expect(Term.profile_terms_for(user)).to eq [legal_term] }
    end
  end
end
