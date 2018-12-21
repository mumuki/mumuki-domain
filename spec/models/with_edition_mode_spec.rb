require 'spec_helper'

describe WithEditionMode do

  let(:guide) { create :guide, extra: 'some guide extra code' }
  let(:exercise) { create(:exercise, description: '$some_string', extra: 'some exercise extra code', guide: guide, randomizations: { some_string: { type: :one_of, value: %w(some string) } }) }

  context 'with edition_mode off it works as usual' do
    it { expect(exercise.extra).to eq "some guide extra code\nsome exercise extra code\n" }
    it { expect(exercise.description).to eq 'some' }
  end

  context 'with edition_mode on it simply returns the field as is' do
    before { exercise.editable! }

    it { expect(exercise.extra).to eq 'some exercise extra code' }
    it { expect(exercise.description).to eq '$some_string'}
  end
end
