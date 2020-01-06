require 'spec_helper'

describe Book, organization_workspace: :test do
  let(:book) { Organization.current.book }

  describe 'book normalization' do
    let(:book) { create(:book, slug: 'fLbUlGaReLlI/MuMUkI-saMPle-gUIde') }

    it { expect(book.slug).to eq('flbulgarelli/mumuki-sample-guide') }
  end

  describe 'fork_to!' do
    let(:original_book) do
      create(:book,
        slug: 'original/book',
        chapters: [
          create(:chapter,
            slug: 'original/topic1',
            lessons: [
              create(:lesson, slug: 'original/guide1'),
              create(:lesson, slug: 'original/guide2')]),
          create(:chapter,
            slug: 'original/topic2',
            lessons: [
              create(:lesson, slug: 'original/guide3'),
              create(:lesson, slug: 'original/guide4')])])
    end

    let(:new_guides) { new_book.reload.chapters.map(&:topic).flat_map(&:lessons).map(&:guide) }

    shared_examples_for 'a successful fork operation' do
      let!(:new_book) { original_book.fork_to! 'new', Mumukit::Sync::Syncer.new(Mumukit::Sync::Store::NullStore.new) }

      it "forks properly" do
        expect(new_book.slug).to eq 'new/book'
        expect(new_book.chapters.map(&:slug)).to eq %w(new/topic1 new/topic2)
        expect(new_guides.map(&:slug)).to eq %w(new/guide1 new/guide2 new/guide3 new/guide4)

        expect(Book.find_by_slug 'new/book').to be_present
        expect(Topic.find_by_slug 'new/topic1').to be_present
        expect(Topic.find_by_slug 'new/topic2').to be_present
        expect(Guide.find_by_slug 'new/guide1').to be_present
        expect(Guide.find_by_slug 'new/guide2').to be_present
        expect(Guide.find_by_slug 'new/guide3').to be_present
        expect(Guide.find_by_slug 'new/guide4').to be_present
      end
    end

    context 'when no content has been previously forked' do
      it_behaves_like 'a successful fork operation'
    end

    context 'when some content has been previously forked' do
      before { create :guide, slug: 'new/guide2' }
      before { create :guide, slug: 'new/guide4' }

      it_behaves_like 'a successful fork operation'
    end
  end

  describe '#next_lesson_for' do
    let!(:chapter) { create(:chapter, lessons: [create(:lesson)]) }
    let(:fresh_user) { create(:user) }

    before { reindex_current_organization! }

    it { expect(book.next_lesson_for(nil)).to eq book.first_lesson }
    it { expect(book.next_lesson_for(fresh_user)).to eq book.first_lesson }
  end

  describe '#rebuild!' do
    let(:chapter_1) { build(:chapter, number: 10) }
    let(:chapter_2) { build(:chapter, number: 8) }

    let(:lesson_1) { create(:lesson) }
    let(:lesson_2) { create(:lesson) }
    let(:lesson_3) { create(:lesson) }

    let(:guide_1) { lesson_1.guide }
    let(:guide_2) { lesson_2.guide }
    let(:guide_3) { lesson_3.guide }

    context 'when chapter is rebuilt after book rebuilt' do
      before do
        book.description = '#foo'
        book.rebuild_chapters!([chapter_1, chapter_2])

        chapter_1.rebuild_lessons!([lesson_1, lesson_2])
        chapter_2.rebuild_lessons!([lesson_3])
      end


      it "rebuilds successfully" do
        expect(book.description).to eq '#foo'
        expect(book.description_html).to eq "<h1>foo</h1>\n"

        expect(Chapter.count).to eq 2
        expect(book.chapters).to eq [chapter_1, chapter_2]
        expect(chapter_1.guides).to eq [guide_1, guide_2]
        expect(chapter_2.guides).to eq [guide_3]
        expect(chapter_1.number).to eq 1
        expect(chapter_2.number).to eq 2
      end
    end

    context 'when some chapters are orphan' do
      let(:orphan_chapter) { build(:chapter, book: nil) }
      before do
        book.description = '#foo'
        book.rebuild_chapters!([chapter_1, orphan_chapter, chapter_2])

        chapter_1.rebuild_lessons!([lesson_1, lesson_2])
        chapter_2.rebuild_lessons!([lesson_3])
      end

      it "rebuilds successfully" do
        expect(book.description).to eq '#foo'
        expect(book.description_html).to eq "<h1>foo</h1>\n"

        expect(Chapter.count).to eq 3
        expect(book.chapters).to eq [chapter_1, orphan_chapter, chapter_2]
        expect(chapter_1.guides).to eq [guide_1, guide_2]
        expect(chapter_2.guides).to eq [guide_3]
        expect(chapter_1.number).to eq 1
        expect(orphan_chapter.number).to eq 2
        expect(chapter_2.number).to eq 3
      end
    end


    context 'when chapter is created before book rebuilt' do
      before do
        chapter_1.save!
        chapter_2.save!

        book.description = '#foo'
        book.rebuild_chapters!([chapter_1, chapter_2])

        chapter_1.rebuild_lessons!([lesson_1, lesson_2])
        chapter_2.rebuild_lessons!([lesson_3])
      end

      it "rebuilds successfully" do
        expect(book.description).to eq '#foo'
        expect(book.description_html).to eq "<h1>foo</h1>\n"

        expect(Chapter.count).to eq 2
        expect(book.chapters).to eq [chapter_1, chapter_2]
        expect(chapter_1.guides).to eq [guide_1, guide_2]
        expect(chapter_2.guides).to eq [guide_3]
        expect(chapter_1.number).to eq 1
        expect(chapter_2.number).to eq 2
      end
    end

    context 'when chapter is rebuilt before book rebuilt' do
      before do
        chapter_1.rebuild_lessons!([lesson_1, lesson_2])
        chapter_2.rebuild_lessons!([lesson_3])

        book.description = '#foo'
        book.rebuild_chapters!([chapter_1, chapter_2])
      end

      it "rebuilds successfully" do
        expect(book.description).to eq '#foo'
        expect(book.description_html).to eq "<h1>foo</h1>\n"

        expect(Chapter.count).to eq 2
        expect(book.chapters).to eq [chapter_1, chapter_2]
        expect(chapter_1.number).to eq 1
        expect(chapter_2.number).to eq 2
        expect(chapter_1.guides).to eq [guide_1, guide_2]
        expect(chapter_2.guides).to eq [guide_3]
      end
    end

    context 'when rebuilt content changes' do
      before { book.rebuild_chapters!([chapter_1, chapter_2]) }

      let!(:usage_1) { Usage.find_by parent_item: chapter_1 }
      let!(:usage_2) { Usage.find_by parent_item: chapter_2 }

      before { book.rebuild_chapters!([chapter_2]) }

      it { expect { chapter_1.reload }.to raise_error ActiveRecord::RecordNotFound }
      it { expect { chapter_2.reload }.to_not raise_error }
      it { expect { usage_1.reload }.to raise_error ActiveRecord::RecordNotFound }
      it { expect { usage_2.reload }.to_not raise_error }
      it { expect(Chapter.count).to eq 1 }
    end
  end
end
