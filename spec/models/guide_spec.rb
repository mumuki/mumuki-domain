require 'spec_helper'

describe Guide do
  let!(:extra_user) { create(:user, first_name: 'Ignatius', last_name: 'Reilly') }
  let(:guide) { create(:guide) }

  describe("schema fields are in sync") do
    let(:resource_h_fields) { Guide.new(language: Language.new).to_expanded_resource_h.keys - [:exercises]}
    let(:schema_fields) { Mumuki::Domain::Store::Github::GuideSchema.fields.map(&:reverse_name) - [:id, :exercises] }

    it { expect(resource_h_fields).to contain_exactly(*schema_fields) }
  end

  describe 'slug normalization' do
    let(:guide) { create(:guide, slug: 'fLbUlGaReLlI/MuMUkI-saMPle-gUIde') }

    it { expect(guide.slug).to eq('flbulgarelli/mumuki-sample-guide') }
  end

  describe '#destroy' do
    context 'when orphan' do
      it { expect { guide.destroy! }.to_not raise_error }
    end

    context 'when referenced' do
      before do
        create(:chapter,
          slug: 'mumuki/topic1',
          lessons: [create(:lesson, guide: guide)])
      end
      it { expect { guide.destroy! }.to raise_error('Guide is still referenced') }
    end

    context 'when referenced' do
      before do
        create(:chapter,
          slug: 'mumuki/topic1',
          lessons: [create(:lesson, guide: guide)])
      end
      it { expect { guide.delete }.to raise_error('Guide is still referenced') }
    end

    context 'when used' do
      let(:organization) do
        create(:organization, book:
          create(:book,
            slug: 'mumuki/book',
            chapters: [
              create(:chapter,
                slug: 'mumuki/topic1',
                lessons: [create(:lesson, guide: guide)])]))
      end
      before { reindex_organization! organization }
      it { expect { guide.reload.destroy! }.to raise_error('Guide is still in use in organization an-organization') }
    end
  end

  describe '#clear_progress!' do
    let(:an_exercise) { create(:exercise) }
    let(:guide) { create(:indexed_guide) }
    let(:test_organization) { create(:test_organization) }

    before do
      test_organization.switch!
      guide.exercises = [an_exercise]
      an_exercise.submit_solution! extra_user
    end

    context 'when progress is exclusively in one organization' do
      let(:another_exercise) { create(:exercise) }

      before do
        another_exercise.submit_solution! extra_user
        guide.clear_progress!(extra_user, test_organization)
      end

      it 'destroys the guides assignments for the given user and organization' do
        expect(an_exercise.find_assignment_for(extra_user, test_organization)).to be_nil
      end

      it 'does not destroy other guides assignments for the given user and organization' do
        expect(another_exercise.find_assignment_for(extra_user, test_organization)).to be_truthy
      end
    end

    context 'when progress is in more than one organization' do
      let(:another_organization) { create(:another_test_organization) }

      before do
        another_organization.switch!
        an_exercise.submit_solution! extra_user
        guide.clear_progress!(extra_user, test_organization)
      end

      it 'destroys the guides assignments for the given user and organization' do
        expect(an_exercise.find_assignment_for(extra_user, test_organization)).to be_nil
      end
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
        expectations: [{binding: '$randomizedWord', inspection: 'Not:Uses:$randomizedWord'}],
        custom_expectations: 'expect: assigns $randomizedWord;',
        test: 'describe "$randomizedWord" do pending end',
        randomizations: {
          randomizedWord: { type: :one_of, value: %w(some) }
        })}

    it { expect(exercise.default_content).to eq 'x = "some" /*...previousSolution...*/' }
    it { expect(exercise.description).to eq "works with some" }
    it { expect(exercise.extra).to eq "guide extra\nexercise extra\n" }
    it { expect(exercise.hint).to eq "try some" }
    it { expect(exercise.custom_expectations).to eq "expect: assigns some;\n" }
    it { expect(exercise.expectations).to eq [
          {'binding' => 'some', 'inspection' => 'Not:Uses:some'},
          {'binding' => 'guide', 'inspection' => 'Uses:expectations'}] }
    it { expect(exercise.test).to eq 'describe "some" do pending end' }

    it { expect(exercise.to_resource_h).to json_eq({
              default_content: 'x = "$randomizedWord" /*...previousSolution...*/',
              description: 'works with $randomizedWord',
              extra: 'exercise extra',
              hint: 'try $randomizedWord',
              expectations: [{binding: '$randomizedWord', inspection: 'Not:Uses:$randomizedWord'}],
              custom_expectations: 'expect: assigns $randomizedWord;',
              test: 'describe "$randomizedWord" do pending end'
            },
            only: Exercise::RANDOMIZED_FIELDS) }
  end

  describe '#to_resource_h' do
    let(:guide) do
      create :guide,
            name: 'Introduction to Python',
            slug: 'mumukiproject/python-guide',
            description: 'Lets introduce python',
            language: python,
            exercises: [
              create(:reading, name: 'This is python', language: python, bibliotheca_id: 10),
              create(:problem, name: 'Say hello', language: python, bibliotheca_id: 11),
              create(:playground, name: 'Some functions', language: python, bibliotheca_id: 12)
            ]
    end

    let(:python) do
      create :language, name: 'python', extension: 'py', test_extension: 'py'
    end

    it { expect(guide.to_resource_h).to json_eq beta: false,
                                                expectations: [],
                                                type: "learning",
                                                id_format: "%05d",
                                                private: false,
                                                settings: {},
                                                name: "Introduction to Python",
                                                description: "Lets introduce python",
                                                locale: "en",
                                                slug: "mumukiproject/python-guide",
                                                exercises: [ {
                                                  name: "This is python",
                                                  id: 10,
                                                  locale: "en",
                                                  layout: "input_bottom",
                                                  tag_list: [],
                                                  extra_visible: false,
                                                  manual_evaluation: false,
                                                  editor: 0,
                                                  assistance_rules: [],
                                                  randomizations: {},
                                                  choices: [],
                                                  type: "reading",
                                                  settings: {},
                                                  description: "Simple reading"
                                                }, {
                                                  name: "Say hello",
                                                  id: 11,
                                                  locale: "en",
                                                  layout: "input_right",
                                                  tag_list: [],
                                                  extra_visible: false,
                                                  manual_evaluation: false,
                                                  editor: "code",
                                                  assistance_rules: [],
                                                  randomizations: {},
                                                  choices: [],
                                                  type: "problem",
                                                  expectations: [],
                                                  settings: {},
                                                  description: "Simple problem",
                                                  test: "dont care"
                                                }, {
                                                  name: "Some functions",
                                                  id: 12,
                                                  locale: "en",
                                                  layout: "input_right",
                                                  tag_list: [],
                                                  extra_visible: false,
                                                  manual_evaluation: false,
                                                  editor: 0,
                                                  assistance_rules: [],
                                                  randomizations: {},
                                                  choices: [],
                                                  type: "playground",
                                                  settings: {},
                                                  description: "Simple playground"
                                                }],
                                                language: {
                                                  name: "python",
                                                  extension: 'py',
                                                  test_extension: 'py'
                                                }
                                              }
  end

  describe 'transparent navigation api' do
    let!(:guide) { create(:guide, slug: 'foo/bar') }
    let(:params) { { organization: 'foo', repository: 'bar' } }

    it { expect(guide.transparent_id).to eq 'foo/bar' }
    it { expect(guide.transparent_params).to eq params }
    it { expect(Guide.find_transparently!(params)).to eq guide }
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
