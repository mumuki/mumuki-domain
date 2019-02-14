require 'spec_helper'

describe Guide do
  let!(:extra_user) { create(:user, first_name: 'Ignatius', last_name: 'Reilly') }
  let(:guide) { create(:guide) }

  describe '#clear_progress!' do
    let(:an_exercise) { create(:exercise) }
    let(:another_exercise) { create(:exercise) }

    before do
      guide.exercises = [an_exercise]
      an_exercise.submit_solution! extra_user
      another_exercise.submit_solution! extra_user
      guide.clear_progress!(extra_user)
    end

    it 'destroys the guides assignments for the given user' do
      expect(an_exercise.find_assignment_for(extra_user)).to be_nil
    end

    it 'does not destroy other guides assignments' do
      expect(another_exercise.find_assignment_for(extra_user)).to be_truthy
    end
  end

  describe 'customizations' do
    let!(:guide) {
      create(:guide,
        extra: 'guide extra',
        expectations: [{binding: 'guide', inspection: 'Uses:expectations'}],
        exercises: [exercise])}
    let(:exercise) {
      build(:exercise,
        default_content: 'x = "$randomizedWord" /*...previousSolution...*/',
        description: 'works with $randomizedWord',
        extra: 'exercise extra',
        hint: 'try $randomizedWord',
        test: 'describe "$randomizedWord" do pending end',
        randomizations: {
          randomizedWord: { type: :one_of, value: %w(some) }
        })}

    it { expect(exercise.default_content).to eq 'x = "some" /*...previousSolution...*/' }
    it { expect(exercise.description).to eq "works with some" }
    it { expect(exercise.expectations).to eq guide.expectations }
    it { expect(exercise.extra).to eq "guide extra\nexercise extra\n" }
    it { expect(exercise.hint).to eq "try some" }
    it { expect(exercise.test).to eq 'describe "some" do pending end' }

    it { expect(exercise.to_resource_h).to json_eq({
              default_content: 'x = "$randomizedWord" /*...previousSolution...*/',
              description: 'works with $randomizedWord',
              expectations: [],
              extra: 'exercise extra',
              hint: 'try $randomizedWord',
              test: 'describe "$randomizedWord" do pending end'
            },
            only: Exercise::RANDOMIZED_FIELDS) }
  end

  describe '#fork!' do
    let(:syncer) { double(:syncer) }
    let!(:guide_from) { create :guide, slug: 'foo/bar' }
    let(:slug_from) { guide_from.slug }
    let(:slug_to) { 'baz/bar'.to_mumukit_slug }
    let(:guide_to) { Guide.find_by_slug! slug_to.to_s }
    let!(:guide) { create(:guide, slug: 'test/bar') }

    context 'fork works' do
      before { expect(syncer).to receive(:export!).with(instance_of(Guide)) }
      before { Guide.find_by_slug!(slug_from).fork_to! 'baz', syncer }
      it { expect(guide_from.to_resource_h).to json_eq guide_to.to_resource_h, except: [:slug] }
    end

    context 'fork does not work if guide already exists' do
      before { expect(syncer).to_not receive(:export!) }
      it { expect { Guide.find_by_slug!(slug_from).fork_to! 'test', syncer }.to raise_error ActiveRecord::RecordInvalid }
    end
  end

  describe 'slug normalization' do
    let(:guide) { create(:guide, slug: 'fLbUlGaReLlI/MuMUkI-saMPle-gUIde') }

    it { expect(guide.slug).to eq('flbulgarelli/mumuki-sample-guide') }
  end

  describe '#to_markdownified_resource_h' do
    subject { guide.to_markdownified_resource_h }
    context 'description' do
      let(:guide) { create(:guide, description: '`foo = (+)`') }
      it { expect(subject[:description]).to eq("<p><code>foo = (+)</code></p>\n") }
    end
    context 'corollary' do
      let(:guide) { create(:guide, corollary: '[Google](https://google.com)') }
      it { expect(subject[:corollary]).to eq("<p><a title=\"\" href=\"https://google.com\" target=\"_blank\">Google</a></p>\n") }
    end
    context 'teacher_info' do
      let(:guide) { create(:guide, teacher_info: '**foo**') }
      it { expect(subject[:teacher_info]).to eq("<p><strong>foo</strong></p>\n") }
    end
    context 'exercises' do
      let(:guide) { create(:guide, exercises: [exercise]) }
      subject { guide.to_markdownified_resource_h[:exercises].first }

      context 'description' do
        let(:exercise) { build(:exercise, description: '`foo = (+)`') }
        it { expect(subject[:description]).to eq("<p><code>foo = (+)</code></p>\n") }
      end
      context 'corollary' do
        let(:exercise) { build(:exercise, corollary: '[Google](https://google.com)') }
        it { expect(subject[:corollary]).to eq("<p><a title=\"\" href=\"https://google.com\" target=\"_blank\">Google</a></p>\n") }
      end
      context 'teacher_info' do
        let(:exercise) { build(:exercise, teacher_info: '**foo**') }
        it { expect(subject[:teacher_info]).to eq("<p><strong>foo</strong></p>\n") }
      end
      context 'hint' do
        let(:exercise) { build(:exercise, hint: '***foo***') }
        it { expect(subject[:hint]).to eq("<p><strong><em>foo</em></strong></p>\n") }
      end
    end
  end
end
