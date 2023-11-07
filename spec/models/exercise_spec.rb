require 'spec_helper'

describe Exercise, organization_workspace: :test do
  let(:exercise) { create(:exercise) }
  let(:user) { create(:user, first_name: 'Orlo') }

  describe "schema fields are in sync" do
    let(:resource_h_fields) { Exercise.new(guide: Guide.new, language: Language.new).to_expanded_resource_h.keys }
    let(:schema_fields) { Mumuki::Domain::Store::Github::ExerciseSchema.fields.map(&:reverse_name) }

    it { expect(resource_h_fields).to contain_exactly(*schema_fields) }
  end

  describe '#to_resource_h' do
    let(:exercise) { create(:problem, name: 'Say hello', description: 'say _hello_', layout: 'input_bottom', language: python, bibliotheca_id: 11, locale: 'en') }
    let(:python) { create :language, name: 'python', extension: 'py', test_extension: 'py' }

    before { exercise.guide.update! language: python }

    it { expect(exercise.to_resource_h).to json_eq name: "Say hello",
                                                   id: 11,
                                                   locale: 'en',
                                                   layout: 'input_bottom',
                                                   tag_list: [],
                                                   extra_visible: false,
                                                   manual_evaluation: false,
                                                   editor: 'code',
                                                   assistance_rules: [],
                                                   randomizations: {},
                                                   choices: [],
                                                   type: "problem",
                                                   settings: {},
                                                   test: 'dont care',
                                                   offline_test: {},
                                                   expectations: [],
                                                   description: "say _hello_" }

  it { expect(exercise.to_resource_h markdownified: true).to json_eq name: "Say hello",
                                                                     id: 11,
                                                                     locale: 'en',
                                                                     layout: 'input_bottom',
                                                                     tag_list: [],
                                                                     extra_visible: false,
                                                                     manual_evaluation: false,
                                                                     editor: 'code',
                                                                     assistance_rules: [],
                                                                     randomizations: {},
                                                                     choices: [],
                                                                     type: "problem",
                                                                     settings: {},
                                                                     test: 'dont care',
                                                                     offline_test: {},
                                                                     expectations: [],
                                                                     description: "<p>say <em>hello</em></p>\n" }

  it { expect(exercise.to_resource_h embed_language: true).to json_eq name: "Say hello",
                                                                      id: 11,
                                                                      locale: 'en',
                                                                      layout: 'input_bottom',
                                                                      tag_list: [],
                                                                      extra_visible: false,
                                                                      manual_evaluation: false,
                                                                      editor: 'code',
                                                                      assistance_rules: [],
                                                                      randomizations: {},
                                                                      choices: [],
                                                                      type: "problem",
                                                                      settings: {},
                                                                      test: 'dont care',
                                                                      offline_test: {},
                                                                      expectations: [],
                                                                      description: "say _hello_",
                                                                      language: { name: 'python', extension: 'py', test_extension: 'py' } }
  end

  describe '#choice_values' do
    context 'when choices are in 6.0 format' do
      let(:choices) { [{value: '1492', checked: false}, {value: '1453', checked: true}, {value: '1773', checked: false}] }
      let(:exercise) { build(:exercise, description: 'when did byzantine empire fall?', choices: choices) }

      it { expect(exercise.choices).to eq choices }
      it { expect(exercise[:choice_values]).to be_blank }
      it { expect(exercise.choice_values).to eq %w(1492 1453 1773) }
      it { expect(exercise.choice_index_for '1492').to eq 0 }
      it { expect(exercise.choice_index_for '1773').to eq 2 }
    end
  end

  describe 'transparent navigation api' do
    let(:guide) { create(:guide, slug: 'foo/bar') }
    let!(:exercise) { create(:exercise, guide: guide, bibliotheca_id: 4) }
    let(:params) { { organization: 'foo', repository: 'bar', bibliotheca_id: 4 } }

    it { expect(exercise.transparent_id).to eq 'foo/bar/4' }
    it { expect(exercise.transparent_params).to eq params }
    it { expect(Exercise.find_transparently!(params)).to eq exercise }
  end

  describe 'locate!' do
    let(:guide) { create(:guide, slug: 'foo/bar') }
    let(:exercise) { create(:exercise, guide: guide, bibliotheca_id: 4) }

    it { expect(Exercise.locate!([guide.slug, exercise.bibliotheca_id])).to eq exercise }
  end

  describe '#new_solution' do
    context 'when there is default content' do
      let(:exercise) { create(:exercise, default_content: 'foo') }

      it { expect(exercise.new_solution.content).to eq 'foo' }
    end

    context 'when there is no default content' do
      let(:exercise) { create(:exercise) }

      it { expect(exercise.new_solution.content).to be_blank }
    end
  end

  describe '#next_for' do
    context 'when exercise has no guide' do
      it { expect(exercise.next_for(user)).to be nil }
    end
    context 'when exercise belong to a guide with a single exercise' do
      let(:exercise_within_guide) { create(:exercise, guide: guide) }
      let(:guide) { create(:guide) }

      it { expect(exercise_within_guide.next_for(user)).to be nil }
    end
    context 'when exercise belongs to a guide with two exercises' do
      let!(:exercise_within_guide) { create(:exercise, guide: guide, number: 2) }
      let!(:alternative_exercise) { create(:exercise, guide: guide, number: 3) }
      let!(:guide) { create(:guide) }

      it { expect(exercise_within_guide.next_for(user)).to eq alternative_exercise }
    end

    context 'when exercise belongs to a guide with two exercises and alternative exercise has been solved',
            organization_workspace: :test do
      let(:exercise_within_guide) { create(:exercise, guide: guide) }
      let!(:alternative_exercise) { create(:exercise, guide: guide) }
      let(:guide) { create(:indexed_guide) }

      before { alternative_exercise.submit_solution!(user, content: 'foo').passed! }

      it { expect(exercise_within_guide.next_for(user)).to be nil }
    end

    context 'when exercise belongs to a guide with two exercises and alternative exercise has been submitted but not solved',
            organization_workspace: :test do
      let!(:exercise_within_guide) { create(:exercise, guide: guide, number: 2) }
      let!(:alternative_exercise) { create(:exercise, guide: guide, number: 3) }
      let(:guide) { create(:guide) }

      before { alternative_exercise.submit_solution!(user, content: 'foo') }

      it { expect(guide.pending_exercises(user)).to_not eq [alternative_exercise, exercise_within_guide] }
      it { expect(guide.next_exercise(user)).to_not be nil }
      it { expect(exercise_within_guide.next_for(user)).to eq alternative_exercise }
    end

    context 'when exercise belongs to a guide with two exercises and alternative exercise is pending manual evaluation',
            organization_workspace: :test do
      let!(:exercise_within_guide) { create(:exercise, guide: guide, number: 2) }
      let!(:alternative_exercise) { create(:exercise, guide: guide, number: 3) }
      let(:guide) { create(:guide) }

      before { alternative_exercise.submit_solution!(user, content: 'foo').manual_evaluation_pending! }

      it { expect(guide.pending_exercises(user)).to eq [exercise_within_guide] }
      it { expect(guide.next_exercise(user)).to eq exercise_within_guide }
      it { expect(exercise_within_guide.next_for(user)).to be nil }
    end

    context 'when no user present' do
      let(:guide) { create(:guide, exercises: create_list(:exercise, 3)) }

      it { expect(guide.next_exercise(nil)).to be guide.exercises.first }
    end
  end

  describe '#extra' do
    context 'when exercise has no extra code' do
      it { expect(exercise.extra).to eq '' }
    end

    context 'when exercise has extra code and has no guide' do
      let!(:exercise_with_extra) { create(:exercise, extra: 'exercise extra code') }

      it { expect(exercise_with_extra.extra).to eq "exercise extra code\n" }
    end

    context 'when exercise has extra code and ends with new line and has no guide' do
      let!(:exercise_with_extra) { create(:exercise, extra: "exercise extra code\n") }

      it { expect(exercise_with_extra.extra).to eq "exercise extra code\n" }
    end

    context 'when exercise has extra code and belongs to a guide with no extra code' do
      let!(:exercise_with_extra) { create(:exercise, guide: guide, extra: 'exercise extra code') }
      let!(:guide) { create(:guide) }

      it { expect(exercise_with_extra.extra).to eq "exercise extra code\n" }
    end

    context 'when exercise has extra code with trailing whitespaces
             and belongs to a guide with no extra code' do
      let!(:exercise_with_extra) { create(:exercise, guide: guide, extra: "\nexercise extra code \n") }
      let!(:guide) { create(:guide) }

      it { expect(exercise_with_extra.extra).to eq "exercise extra code\n" }
    end

    context 'when exercise has extra code and belongs to a guide with extra code' do
      let!(:exercise_with_extra) { create(:exercise, guide: guide, extra: 'exercise extra code') }
      let!(:guide) { create(:guide, extra: 'guide extra code') }

      it { expect(exercise_with_extra.extra).to eq "guide extra code\nexercise extra code\n" }
      it { expect(exercise_with_extra[:extra]).to eq 'exercise extra code' }
    end
  end

  describe '#extra_preview', organization_workspace: :test do
    let(:haskell) { create(:haskell) }
    let(:guide) { create(:guide,
                         extra: 'f x = 1',
                         language: haskell,
                         exercises: [create(:exercise,
                                            extra: 'g y = y + 3',
                                            language: haskell)]) }
    let(:exercise) { guide.exercises.first }

    it { expect(exercise.assignment_for(user).extra_preview).to eq "```haskell\nf x = 1\ng y = y + 3\n```" }
  end

  describe '#submit_solution!', organization_workspace: :test do
    let(:test_organization) { Organization.current }
    let(:another_organization) { create(:public_organization) }

    context 'when user does no submission' do
      it 'should not find a submission' do
        expect(exercise.find_assignment_for(user, test_organization)).to be_blank
      end
    end

    context 'when user does a submission in an organization' do
      before { exercise.submit_solution!(user) }

      it 'should find a submission for that user and organization' do
        expect(exercise.find_assignment_for(user, test_organization)).to be_present
      end
    end
  end

  describe '#destroy' do
    context 'when there are no submissions' do
      it { exercise.destroy! }
    end

    context 'when there are submissions', organization_workspace: :test do
      let!(:assignment) { create(:assignment, exercise: exercise) }
      before { exercise.destroy! }
      it { expect { Assignment.find(assignment.id) }.to raise_error(ActiveRecord::RecordNotFound) }
    end

  end

  describe '#previous_solution_for', organization_workspace: :test do
    context 'when user has a single submission for the exercise' do
      let!(:assignment) { exercise.submit_solution!(user, content: 'foo') }

      it { expect(assignment.current_content).to eq assignment.solution }
    end

    context 'when user has no submissions for the exercise' do
      it { expect(exercise.assignment_for(user).current_content).to eq '' }
    end

    context 'when using an interpolation' do
      let!(:chapter) {
        create(:chapter, lessons: [
          create(:lesson, exercises: [
            first_exercise,
            second_exercise,
            previous_exercise,
            exercise
          ])]) }

      let(:first_exercise) { create(:exercise) }
      let(:second_exercise) { create(:exercise) }
      let(:previous_exercise) { create(:exercise) }

      before { reindex_current_organization! }

      context 'when interpolation is in default_content' do
        let(:assignment) { exercise.assignment_for(user) }

        describe 'right previous content' do
          let(:exercise) { create(:exercise, default_content: interpolation) }

          context 'using previousContent' do
            let(:interpolation) { '/*...previousContent...*/' }

            context 'has previous submission' do
              before { previous_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.current_content).to eq 'foobar' }
            end

            context 'does not have previous submission' do
              it { expect(assignment.current_content).to eq '' }
            end
          end
          context 'using previousSolution' do
            let(:interpolation) { '/*...previousSolution...*/' }

            context 'has previous submission' do
              before { previous_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.current_content).to eq 'foobar' }
            end

            context 'does not have previous submission' do
              it { expect(assignment.current_content).to eq '' }
            end
          end
        end

        describe 'indexed previous content' do
          context '-2 index' do
            let(:exercise) { create(:exercise, default_content: '/*...solution[-2]...*/') }

            context 'has previous submission' do
              before { second_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.current_content).to eq 'foobar' }
            end
          end
          context '-1 index' do
            let(:exercise) { create(:exercise, default_content: '/*...solution[-1]...*/') }

            context 'has previous submission' do
              before { previous_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.current_content).to eq 'foobar' }
            end

            context 'does not have previous submission' do
              it { expect(assignment.current_content).to eq '' }
            end
          end
          context '1 index' do
            let(:exercise) { create(:exercise, default_content: '/*...solution[1]...*/') }

            context 'has previous submission' do
              before { first_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.current_content).to eq 'foobar' }
            end
          end
          context '2 index' do
            let(:exercise) { create(:exercise, default_content: '/*...solution[2]...*/') }

            context 'has previous submission' do
              before { second_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.current_content).to eq 'foobar' }
            end
          end
          context '3 index' do
            let(:exercise) { create(:exercise, default_content: '/*...solution[3]...*/') }

            context 'has previous submission' do
              before { previous_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.current_content).to eq 'foobar' }
            end
          end
        end
      end
      context 'when interpolation is in test' do
        let(:assignment) { exercise.assignment_for(user) }

        context 'using user_first_name'  do
          let(:exercise) { create(:exercise, test: "<div>Hola #{interpolation}</div>") }
          let(:interpolation) { '/*...user_first_name...*/' }

          it { expect(assignment.test).to eq "<div>Hola Orlo</div>" }
        end

        context 'and test is nil'  do
          let(:exercise) { create(:exercise, test: nil, expectations: [{binding: "program", inspection: 'Uses:foo'}]) }

          it { expect(assignment.test).to eq nil }
        end
      end
      context 'when interpolation is in extra' do
        let(:assignment) { exercise.assignment_for(user) }

        describe 'right previous content' do
          let(:exercise) { create(:exercise, extra: interpolation) }

          context 'using previousContent' do
            let(:interpolation) { '/*...previousContent...*/' }

            context 'has previous submission' do
              before { previous_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.extra).to eq "foobar\n" }
            end

            context 'does not have previous submission' do
              it { expect(assignment.extra).to eq "\n" }
            end
          end
          context 'using previousSolution' do
            let(:interpolation) { '/*...previousSolution...*/' }

            context 'has previous submission' do
              before { previous_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.extra).to eq "foobar\n" }
            end

            context 'does not have previous submission' do
              it { expect(assignment.extra).to eq "\n" }
            end
          end
        end

        describe 'indexed previous content' do
          context '-2 index' do
            let(:exercise) { create(:exercise, extra: '/*...solution[-2]...*/') }

            context 'has previous submission' do
              before { second_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.extra).to eq "foobar\n" }
            end
          end
          context '-1 index' do
            let(:exercise) { create(:exercise, extra: '/*...solution[-1]...*/') }

            context 'has previous submission' do
              before { previous_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.extra).to eq "foobar\n" }
            end

            context 'does not have previous submission' do
              it { expect(assignment.extra).to eq "\n" }
            end
          end
          context '1 index' do
            let(:exercise) { create(:exercise, extra: '/*...solution[1]...*/') }

            context 'has previous submission' do
              before { first_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.extra).to eq "foobar\n" }
            end
          end
          context '2 index' do
            let(:exercise) { create(:exercise, extra: '/*...solution[2]...*/') }

            context 'has previous submission' do
              before { second_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.extra).to eq "foobar\n" }
            end
          end
          context '3 index' do
            let(:exercise) { create(:exercise, extra: '/*...solution[3]...*/') }

            context 'has previous submission' do
              before { previous_exercise.submit_solution!(user, content: 'foobar') }
              it { expect(assignment.extra).to eq "foobar\n" }
            end
          end
        end
      end
    end

    context 'when user has multiple submission for the exercise' do
      before { exercise.submit_solution!(user, content: 'foo') }
      let!(:assignment) { exercise.submit_solution!(user, content: 'bar') }

      it { expect(assignment.current_content).to eq assignment.solution }
    end

    context 'when user has no solution and exercise has default content' do
      let(:exercise) { create(:exercise, default_content: '#write here...') }
      let(:assignment) { exercise.assignment_for user }

      it { expect(assignment.current_content).to eq '#write here...' }
    end
  end

  describe '#guide_done_for?', organization_workspace: :test do
    context 'when it does not belong to a guide' do
      it { expect(exercise.guide_done_for?(user)).to be false }
    end

    context 'when it belongs to an unfinished guide' do
      let!(:guide) { create(:indexed_guide) }
      let!(:exercise_unfinished) { create(:exercise, guide: guide) }
      let!(:exercise_finished) { create(:exercise, guide: guide) }

      before do
        exercise_finished.submit_solution!(user, content: 'foo').passed!
      end

      it { expect(exercise_finished.guide_done_for?(user)).to be false }
    end

    context 'when it belongs to a finished guide' do
      let!(:guide) { create(:indexed_guide) }
      let!(:exercise_finished) { create(:exercise, guide: guide) }
      let!(:exercise_finished2) { create(:exercise, guide: guide) }

      before do
        exercise_finished.submit_solution!(user, content: 'foo').passed!
        exercise_finished2.submit_solution!(user, content: 'foo').passed!
      end

      it { expect(exercise_finished.guide_done_for?(user)).to be true }
    end
  end

  describe '#language' do
    let(:guide) { create(:guide) }
    let(:exercise_within_guide) { create(:exercise, guide: guide, language: guide.language) }
    let(:other_language) { create(:language) }

    context 'when has no guide' do
      it { expect(exercise.valid?).to be true }
    end

    context 'when has guide and is consistent' do
      it { expect(exercise_within_guide.valid?).to be true }
    end
  end

  describe '#friendly_name', organization_workspace: :test do
    it { expect(Exercise.find(exercise.friendly_name)).to eq exercise }
    it { expect(Problem.find(exercise.friendly_name)).to eq exercise }
  end

  describe '#splitted_description' do
    let(:exercise) { create(:exercise, description: "**Foo**\n\n> _Bar_") }
    it { expect(exercise.description_context).to eq "<p><strong>Foo</strong></p>\n" }
    it { expect(exercise.description_task).to eq "<p><em>Bar</em></p>\n" }
  end

  describe '#validate!' do
    context 'non-empty, valid randomizations' do
      let(:exercise) { build(:exercise,
                            randomizations: {
                              some_word: { type: :one_of, value: %w('some' 'word') },
                              some_number: { type: :range, value: [1, 10] } }) }
      it { expect { exercise.validate! }.not_to raise_error }
    end

    context 'empty inspections' do
      let(:exercise) { build(:exercise, expectations: [{ "binding" => "program", "inspection" => "" }]) }
      it { expect { exercise.validate! }.to raise_error(/expectations format is invalid/i) }
    end

    context 'invalid assistance_rules' do
      let(:exercise) { build(:exercise, assistance_rules: [{ when: 'content_empty', then: ['asd'] }]) }
      it { expect { exercise.validate! }.to raise_error(/assistance rules format is invalid/i) }
    end

    context 'invalid randomizations' do
      let(:exercise) { build(:exercise, randomizations: { type: :range, value: [1] }) }
      it { expect { exercise.validate! }.to raise_error(/randomizations format is invalid/i) }
    end
  end

  describe '#files_for' do
    before { create(:language, extension: 'js', highlight_mode: 'javascript') }
    let(:current_content) { "/*<index.html#*/a html content/*#index.html>*/\n/*<a_file.js#*/a js content/*#a_file.js>*/" }
    let(:assignment) { build(:assignment, exercise: exercise, solution: current_content) }
    let(:files) { exercise.files_for(current_content) }

    it { expect(files.count).to eq 2 }
    it { expect(files[0]).to have_attributes(name: 'index.html', content: 'a html content') }
    it { expect(files[0].highlight_mode).to eq 'html' }
    it { expect(files[1]).to have_attributes(name: 'a_file.js', content: 'a js content') }
    it { expect(files[1].highlight_mode).to eq 'javascript' }
    it { expect(files.to_json).to eq assignment.files.to_json }
  end

  describe 'limited? && results_hidden?' do
    let(:choice) { create(:multiple_choice) }
    let(:problem) { create(:problem) }
    let(:guide) { create(:guide, exercises: [choice, problem]) }

    context 'in regular guide' do
      let!(:chapter) { create(:chapter, lessons: [create(:lesson, guide: guide)]) }
      before { reindex_current_organization! }

      it { expect(choice.limited?).to eq false }
      it { expect(problem.limited?).to eq false }
      it { expect(choice.results_hidden?).to eq false }
      it { expect(problem.results_hidden?).to eq false }
    end

    context 'in choice capped exam' do
      let!(:exam) {create(:exam, max_choice_submissions: 2, guide: guide)}
      it { expect(choice.limited?).to eq true }
      it { expect(problem.limited?).to eq false }
      it { expect(choice.results_hidden?).to eq false }
      it { expect(problem.results_hidden?).to eq false }
    end

    context 'in problem capped exam' do
      let!(:exam) {create(:exam, max_problem_submissions: 2, guide: guide)}
      it { expect(choice.limited?).to eq false }
      it { expect(problem.limited?).to eq true }
      it { expect(choice.results_hidden?).to eq false }
      it { expect(problem.results_hidden?).to eq false }
    end

    context 'in problem capped exam with results hidden for choice' do
      let!(:exam) {create(:exam, max_problem_submissions: 2, results_hidden_for_choices: true, guide: guide)}
      it { expect(choice.limited?).to eq false }
      it { expect(problem.limited?).to eq true }
      it { expect(choice.results_hidden?).to eq true }
      it { expect(problem.results_hidden?).to eq false }
    end

    context 'in choice capped exam with results hidden for choice' do
      let!(:exam) {create(:exam, max_choice_submissions: 2, results_hidden_for_choices: true, guide: guide)}
      it { expect(choice.limited?).to eq false }
      it { expect(problem.limited?).to eq false }
      it { expect(choice.results_hidden?).to eq true }
      it { expect(problem.results_hidden?).to eq false }
    end

    context 'in non-capped exam' do
      let!(:exam) {create(:exam, guide: guide)}
      it { expect(choice.limited?).to eq false }
      it { expect(problem.limited?).to eq false }
      it { expect(choice.results_hidden?).to eq false }
      it { expect(problem.results_hidden?).to eq false }
    end

    context 'in non-capped exam with results hidden for choice' do
      let!(:exam) {create(:exam, results_hidden_for_choices: true, guide: guide)}
      it { expect(choice.limited?).to eq false }
      it { expect(problem.limited?).to eq false }
      it { expect(choice.results_hidden?).to eq true }
      it { expect(problem.results_hidden?).to eq false }
    end
  end
end
