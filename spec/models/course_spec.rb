require 'spec_helper'

describe 'CourseChanged', organization_workspace: :test do
  let(:course_json) do
    {slug: 'test/bar',
     shifts: %w(morning),
     code: 'k2003',
     days: %w(monday wednesday),
     period: '2016',
     description: 'test course'}
  end

  let!(:course) { Course.import_from_resource_h! course_json }

  it { expect(course.organization.courses).to include course }
  it { expect(course.organization.name).to eq 'test' }

  it { expect(course.slug).to eq 'test/bar' }
  it { expect(course.code).to eq 'k2003' }
  it { expect(course.days).to eq %w(monday wednesday) }
  it { expect(course.period).to eq '2016' }
  it { expect(course.canonical_code).to eq '2016-k2003' }

  describe 'status' do
    context 'started' do
      let(:course) { Course.new period_start: 1.day.ago }

      it { expect(course.started?).to be true }
      it { expect(course.ended?).to be false }
    end

    context 'not started' do
      let(:course) { Course.new period_start: 1.day.since }

      it { expect(course.started?).to be false }
      it { expect(course.ended?).to be false }
    end

    context 'ended' do
      let(:course) { Course.new period_end: 1.day.ago }

      it { expect(course.started?).to be false }
      it { expect(course.ended?).to be true }
    end

    context 'not ended' do
      let(:course) { Course.new period_end: 1.day.since }

      it { expect(course.started?).to be false }
      it { expect(course.ended?).to be false }
    end
  end

  describe "#infer_period_range!" do
    before { course.infer_period_range! }

    context 'period and range start' do
      let(:course) { Course.new period: '2021', period_start: DateTime.new(2018, 3, 1) }

      it { expect(course.period_start).to eq DateTime.new(2018, 3, 1) }
      it { expect(course.period_end).to be nil }
    end

    context 'period and range end' do
      let(:course) { Course.new period: '2021', period_end: DateTime.new(2018, 7, 15) }

      it { expect(course.period_start).to be nil }
      it { expect(course.period_end).to eq DateTime.new(2018, 7, 15) }
    end

    context 'no separators' do
      let(:course) { Course.new period: '20181C'}

      it { expect(course.period_start).to eq DateTime.new(2018, 1, 1) }
      it { expect(course.period_end).to eq DateTime.new(2018, 12, 31) }
    end

    context 'with separators' do
      let(:course) { Course.new period: '2020-1C'}

      it { expect(course.period_start).to eq DateTime.new(2020, 1, 1) }
      it { expect(course.period_end).to eq DateTime.new(2020, 12, 31) }
    end

    context 'before foundation' do
      let(:course) { Course.new period: '0000'}

      it { expect(course.period_start).to be nil}
      it { expect(course.period_end).to be nil }
    end

    context 'too into the future' do
      let(:course) { Course.new period: '9999'}

      it { expect(course.period_start).to be nil}
      it { expect(course.period_end).to be nil }
    end

    context 'empty period foundation' do
      let(:course) { Course.new period: nil }

      it { expect(course.period_start).to be nil}
      it { expect(course.period_end).to be nil }
    end
  end

  describe '#invite!' do
    context 'when an invitation has not been created yet' do
      it { expect(course.current_invitation).to be nil }
      it { expect(course.closed?).to be true }
    end

    context 'when an invitation has been created' do
      let(:expiration_date) { 2.days.since.beginning_of_day }
      let!(:invitation) { course.invite! expiration_date }

      it { expect(invitation.expiration_date).to eq expiration_date }
      it { expect(invitation.code).to_not be nil }
      it { expect(course.invitations).to eq [invitation] }
      it { expect(course.current_invitation).to eq invitation }
      it { expect(course.closed?).to be false }
    end

    context 'when an invitation has been created and then re-created before expiration' do
      let(:old_expiration) { 1.day.since.beginning_of_day }

      before { course.invite! old_expiration }
      let!(:invitation) { course.invite! 2.days.since }

      # This behaviour is debatable, but it is the current expected behaviour
      it { expect(invitation.expiration_date).to eq old_expiration }
      it { expect(invitation.code).to_not be nil }
      it { expect(course.invitations.size).to eq 1 }
      it { expect(course.current_invitation).to eq invitation }
      it { expect(course.closed?).to be false }
    end

    context 'when an invitation has been created and then re-created after expiration' do
      before { course.invite! 1.day.ago }

      let(:new_expiration) { 2.days.since.beginning_of_day }
      let!(:invitation) { course.invite! new_expiration }

      it { expect(invitation.expiration_date).to eq new_expiration }
      it { expect(invitation.code).to_not be nil }
      it { expect(course.invitations.size).to eq 2 }
      it { expect(course.current_invitation).to eq invitation }
      it { expect(course.closed?).to be false }
    end
  end
end
