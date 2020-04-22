require 'spec_helper'

describe Stats do
  context 'when someone has not started' do
    let(:stats) { Stats.new(passed: 0, passed_with_warnings: 0, failed: 0, pending: 10, skipped: 0) }
    it { expect(stats.submitted).to eq 0 }
    it { expect(stats.done?).to be false }
    it { expect(stats.started?).to be false }
  end

  context 'when someone has started but is not done' do
    let(:stats) { Stats.new(passed: 3, passed_with_warnings: 2, failed: 1, pending: 3, skipped: 1) }
    it { expect(stats.submitted).to eq 6 }
    it { expect(stats.done?).to be false }
    it { expect(stats.started?).to be true }
  end

  context 'when someone is done' do
    let(:stats) { Stats.new(passed: 7, passed_with_warnings: 2, failed: 0, pending: 0, skipped: 1) }
    it { expect(stats.submitted).to eq 9 }
    it { expect(stats.done?).to be true }
    it { expect(stats.started?).to be true }
  end
end
