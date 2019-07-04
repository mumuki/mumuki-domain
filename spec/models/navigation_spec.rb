require 'spec_helper'

describe 'Navigation', organization_workspace: :test do
  let(:organization_1) { create(:organization, name: 'org1', book: book_1) }
  let(:organization_2) { create(:organization, name: 'org2', book: book_2) }

  let(:book_1) do
    create(:book,
           complements: [create(:complement)],
           chapters: [
               create(:chapter, lessons: [
                   create(:lesson, exercises: [
                       create(:exercise)
                   ]),
                   create(:lesson)
               ])
           ])
  end

  let(:book_2) do
    create(:book,
           complements: [create(:complement)],
           chapters: [
               create(:chapter, lessons: [
                   create(:lesson, exercises: [
                       create(:exercise)
                   ]),
                   create(:lesson)
               ])
           ])
  end

  let(:chapter_1) { book_1.chapters.first }
  let(:chapter_2) { book_2.chapters.first }

  let(:lesson_1) { chapter_1.lessons.first }
  let(:lesson_2) { chapter_2.lessons.first }

  let(:exercise_1) { lesson_1.exercises.first }
  let(:exercise_2) { lesson_2.exercises.first }

  before { reindex_organization! organization_1 }
  before { reindex_organization! organization_2 }

  it 'works with complements' do
    expect(book_1.complements.first.used_in? Organization.current).to be false
    expect(book_1.complements.first.used_in? organization_1).to be true
    expect(book_1.complements.first.used_in? organization_2).to be false

    expect(book_2.complements.first.used_in? Organization.current).to be false
    expect(book_2.complements.first.used_in? organization_1).to be false
    expect(book_2.complements.first.used_in? organization_2).to be true
  end

  it 'works with chapters' do
    expect(chapter_1.used_in? organization_1).to be true
    expect(chapter_1.used_in? organization_2).to be false

    expect(chapter_2.used_in? organization_1).to be false
    expect(chapter_2.used_in? organization_2).to be true
  end

  it 'works with lessons' do
    expect(lesson_1.used_in? organization_1).to be true
    expect(lesson_1.used_in? organization_2).to be false

    expect(lesson_2.used_in? organization_1).to be false
    expect(lesson_2.used_in? organization_2).to be true
  end

  it 'works with exercsies' do
    expect(exercise_1.used_in? organization_1).to be true
    expect(exercise_1.used_in? organization_2).to be false

    expect(exercise_2.used_in? organization_1).to be false
    expect(exercise_2.used_in? organization_2).to be true
  end
end
