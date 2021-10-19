require 'spec_helper'

describe '#to_resource_h', organization_workspace: :test do
  describe Assignment do
    let(:user) {
      create(:user,
        id: 2, email: 'foo@bar.com',
        first_name: 'Homer', last_name: 'Simpson',
        provider: 'auth0', social_id: 'github|gh1234', image_url: 'user_shape.png') }
    describe 'lesson type' do
      let(:lesson) { chapter.lessons.fourth }
      let(:guide) { lesson.guide }
      let(:exercise) { lesson.exercises.first }
      let!(:chapter) {
        create(:chapter, lessons: [
          create(:lesson),
          create(:lesson),
          create(:lesson),
          create(:lesson, exercises: [create(:exercise)])]) }

      before { reindex_current_organization! }

      let(:assignment) { create(:assignment,
                                solution: 'x = 2',
                                status: :passed,
                                submissions_count: 2,
                                submitter: user,
                                submission_id: 'abcd1234',
                                exercise: exercise) }

      it { expect(lesson.number).to eq 4 }
      it do
        expect(assignment.to_resource_h).to json_like(
                           status: :passed,
                           result: nil,
                           expectation_results: [],
                           queries: [],
                           query_results: [],
                           feedback: nil,
                           test_results: nil,
                           submissions_count: 2,
                           attemps_count: 0,
                           manual_evaluation_comment: nil,
                           exercise: {
                             eid: exercise.bibliotheca_id,
                             name: exercise.name,
                             number: exercise.number},
                           guide: {
                             name: guide.name,
                             slug: guide.slug,
                             lesson: {
                               number: 4,
                             },
                             language: {
                               name: guide.language.name
                             },
                             parent: {
                               type: 'Lesson',
                               name: guide.name,
                               position: 4,
                               chapter: {
                                 id: guide.chapter.id,
                                 name: guide.chapter.name
                               }
                             }
                           },
                           submitter: {
                             social_id: 'github|gh1234',
                             name: 'Homer Simpson',
                             email: 'foo@bar.com',
                             uid: assignment.submitter.uid,
                             profile_picture: 'user_shape.png'},
                           sid: 'abcd1234',
                           created_at: assignment.updated_at,
                           content: 'x = 2',
                           organization: 'test')
      end
    end
    describe 'exam type' do
      let(:exercise) { create(:exercise) }
      let!(:exam) { create(:exam, guide: create(:guide, exercises: [exercise])) }
      let(:guide) { exam.guide }
      before { reindex_current_organization! }
      let(:assignment) { create(:assignment,
                                solution: 'x = 2',
                                status: :passed,
                                submissions_count: 2,
                                submitter: user,
                                submission_id: 'abcd1234',
                                exercise: exercise) }
      context 'without randomizations' do
        it do
          expect(assignment.to_resource_h).to json_like(
                             status: :passed,
                             result: nil,
                             expectation_results: [],
                             queries: [],
                             query_results: [],
                             feedback: nil,
                             test_results: nil,
                             submissions_count: 2,
                             attemps_count: 0,
                             manual_evaluation_comment: nil,
                             exercise: {
                               name: exercise.name,
                               number: exercise.number,
                               eid: exercise.bibliotheca_id},
                             guide: {
                               name: guide.name,
                               slug: guide.slug,
                               language: {
                                 name: guide.language.name
                               },
                               parent: {
                                 type: 'Exam',
                                 name: guide.name,
                                 position: nil,
                                 chapter: nil
                               }
                             },
                             submitter: {
                               social_id: 'github|gh1234',
                               name: 'Homer Simpson',
                               email: 'foo@bar.com',
                               profile_picture: 'user_shape.png',
                               uid: assignment.submitter.uid},
                             sid: 'abcd1234',
                             created_at: assignment.updated_at,
                             content: 'x = 2',
                             organization: 'test')

        end
      end

      context 'with randomizations' do
        let(:exercise) do
           create(:exercise, randomizations: {
            some_word: { type: :one_of, value: %w(this) },
            some_number: { type: :range, value: [1, 100] } })
        end
        it do
          expect(assignment.to_resource_h).to json_like(
                             status: :passed,
                             result: nil,
                             expectation_results: [],
                             queries: [],
                             query_results: [],
                             feedback: nil,
                             test_results: nil,
                             submissions_count: 2,
                             attemps_count: 0,
                             manual_evaluation_comment: nil,
                             randomized_values: {
                               some_word: 'this',
                               some_number: assignment.randomized_values['some_number'],
                             },
                             exercise: {
                               name: exercise.name,
                               number: exercise.number,
                               eid: exercise.bibliotheca_id},
                             guide: {
                               name: guide.name,
                               slug: guide.slug,
                               language: {
                                 name: guide.language.name
                               },
                               parent: {
                                 type: 'Exam',
                                 name: guide.name,
                                 position: nil,
                                 chapter: nil
                               }
                             },
                             submitter: {
                               social_id: 'github|gh1234',
                               name: 'Homer Simpson',
                               email: 'foo@bar.com',
                               profile_picture: 'user_shape.png',
                               uid: assignment.submitter.uid},
                             sid: 'abcd1234',
                             created_at: assignment.updated_at,
                             content: 'x = 2',
                             organization: 'test')

        end
      end
    end
    describe 'complementary type' do
      let!(:complement) { create(:complement, guide: create(:guide, exercises: [create(:exercise)])) }
      let(:guide) { complement.guide }
      let(:exercise) { guide.exercises.first }
      before { reindex_current_organization! }
      let(:assignment) { create(:assignment,
                                solution: 'x = 2',
                                status: :passed,
                                submissions_count: 2,
                                submitter: user,
                                submission_id: 'abcd1234',
                                exercise: exercise) }

      it do
        expect(assignment.to_resource_h).to json_like(
                           status: :passed,
                           result: nil,
                           expectation_results: [],
                           queries: [],
                           query_results: [],
                           feedback: nil,
                           test_results: nil,
                           submissions_count: 2,
                           attemps_count: 0,
                           manual_evaluation_comment: nil,
                           exercise: {
                             eid: exercise.bibliotheca_id,
                             name: exercise.name,
                             number: exercise.number},
                           guide: {
                             name: guide.name,
                             slug: guide.slug,
                             language: {
                               name: guide.language.name
                             },
                             parent: {
                               type: 'Complement',
                               name: guide.name,
                               position: nil,
                               chapter: nil
                             }
                           },
                           submitter: {
                             name: 'Homer Simpson',
                             email: 'foo@bar.com',
                             profile_picture: 'user_shape.png',
                             uid: assignment.submitter.uid,
                             social_id: 'github|gh1234'},
                           sid: 'abcd1234',
                           created_at: assignment.updated_at,
                           content: 'x = 2',
                           organization: 'test')

      end
    end
  end
end
