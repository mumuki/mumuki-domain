require 'spec_helper'

describe Mumuki::Domain::NilUser do
  let(:user) { Mumuki::Domain::NilUser }
  let(:organization) { create(:organization) }

  it 'can mock an AR relation' do
    Assignment.new submitter: user
  end

  describe 'assignment' do
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

  describe 'next_for' do
    let(:exercise) { create(:exercise) }

    it { expect(exercise.next_for(user)).to be nil }
  end
end
