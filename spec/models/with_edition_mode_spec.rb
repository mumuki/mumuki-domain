require 'spec_helper'

describe WithEditionMode do

  let(:guide) { create :guide, extra: 'some guide extra code', expectations: [{binding: 'bar', inspection: 'HasBinding'}] }
  let(:exercise) { create :exercise, description: '$some_string', extra: 'some exercise extra code', guide: guide, randomizations: { some_string: { type: :one_of, value: %w(some string) } } }
  let(:exercise_with_expectations) { create :exercise, guide: guide, expectations: [{binding: 'foo', inspection: 'HasBinding'}] }

  context 'with edition_mode off it works as usual' do
    it { expect(exercise.extra).to eq "some guide extra code\nsome exercise extra code\n" }
    it { expect(exercise.description).to eq 'some' }
    it { expect(exercise_with_expectations.expectations).to eq [{'binding' => 'foo', 'inspection' => 'HasBinding'}, {'binding' => 'bar', 'inspection' => 'HasBinding'}] }
  end

  context 'with edition_mode on it simply returns the field as is' do
    before { exercise.edit! }
    before { exercise_with_expectations.edit! }

    it { expect(exercise.extra).to eq 'some exercise extra code' }
    it { expect(exercise.description).to eq '$some_string'}
    it { expect(exercise_with_expectations.expectations).to eq [{'binding' => 'foo', 'inspection' => 'HasBinding'}] }
  end
end
