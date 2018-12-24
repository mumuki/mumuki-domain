require 'spec_helper'

describe WithExpectations do
  let(:exercise) { build(:exercise) }

  context 'when a non-problem exercise' do
    let(:playground) { build(:playground) }
    it { expect(playground.expectations).to be nil }
    it { expect(playground.accumulated_expectations).to be nil }
  end

  context 'when setting empty list' do
    before { exercise.expectations = [] }

    it { expect(exercise.expectations).to eq [] }
  end

  context 'when setting empty yaml' do
    before { exercise.expectations_yaml = [].to_yaml }

    it { expect(exercise.expectations).to eq [] }
  end

  context 'when no expectations' do
    it { expect(exercise.expectations).to eq [] }
  end

  context 'when setting non empty symbolized list' do
    before { exercise.expectations = [{binding: 'foo', inspection: 'HasBinding'}] }

    it { expect(exercise.expectations).to eq [{'binding' => 'foo', 'inspection' => 'HasBinding'}] }
    it { expect(exercise.accumulated_expectations).to eq exercise.expectations }
  end

  context 'when setting non empty stringified list' do
    before { exercise.expectations = [{'binding' => 'foo', 'inspection' => 'HasBinding'}] }

    it { expect(exercise.expectations).to eq [{'binding' => 'foo', 'inspection' => 'HasBinding'}] }
  end

  context 'when setting non empty yaml' do
    before { exercise.expectations_yaml = [{'binding' => 'foo', 'inspection' => 'HasBinding'}].to_yaml }

    it { expect(exercise.expectations).to eq [{'binding' => 'foo', 'inspection' => 'HasBinding'}] }
  end

  context 'when the guide has expectations' do
    let(:guide) { create(:guide) }

    before do
      exercise.language = guide.language
      exercise.expectations = [{binding: 'foo', inspection: 'HasBinding'}]
      exercise.guide = guide

      guide.expectations = [{binding: 'bar', inspection: 'HasBinding'}]
    end

    it { expect(exercise.expectations).to eq [{'binding' => 'foo', 'inspection' => 'HasBinding'}] }
    it { expect(exercise.accumulated_expectations).to eq [
          {'binding' => 'foo', 'inspection' => 'HasBinding'},
          {'binding' => 'bar', 'inspection' => 'HasBinding'}] }
  end
end
