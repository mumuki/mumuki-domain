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
      let(:guide_1) { create :indexed_guide }
      let(:guide_2) { create :indexed_guide }

      let(:chapter_1) { guide_1.chapter }
      let(:chapter_2) { guide_2.chapter }

      before { book.rebuild_chapters!([chapter_1, chapter_2]) }

      let!(:chapter_1_usage) { Usage.find_by parent_item: chapter_1 }
      let!(:chapter_2_usage) { Usage.find_by parent_item: chapter_2 }
      let!(:guide_1_usage) { Usage.find_by item: guide_1 }
      let!(:guide_2_usage) { Usage.find_by item: guide_2 }

      before { book.rebuild_chapters!([chapter_2]) }

      it { expect { chapter_1.reload }.to raise_error ActiveRecord::RecordNotFound }
      it { expect { chapter_2.reload }.to_not raise_error }
      it { expect { chapter_1_usage.reload }.to raise_error ActiveRecord::RecordNotFound }
      it { expect { chapter_2_usage.reload }.to_not raise_error }
      it { expect { guide_1_usage.reload }.to raise_error ActiveRecord::RecordNotFound }
      it { expect { guide_2_usage.reload }.to_not raise_error }
      it { expect(Chapter.count).to eq 1 }
    end
  end


  # Scenarios:
  #
  # - hide mumuki/t1 at 2020-10-10 with messagee 'dfsdfsdf'
  # - hide mumuki/t1 until 2020-10-10 with messagee 'dfsdfsdf'

  # - disable mumuki/t1 at 2020-10-10 with messagee 'dfsdfsdf'
  # - disable mumuki/t1 until 2020-10-10 with messagee 'dfsdfsdf'

  # - hide mumuki/t1 until previous content finished
  # - disable mumuki/t1 until previous content finished

  # - hide * until previous content finished

  # todo: compile, add to course, create workspaces, reify AccessLevel and Action, active/inactive support, source_code

  describe 'access rules' do
    let(:book) { create(:book, chapters: [chapter_1, chapter_2, chapter_3 ]) }
    let(:chapter_1) { build(:chapter, slug: 'mumuki/t1') }
    let(:chapter_2) { build(:chapter, slug: 'mumuki/t2') }
    let(:chapter_3) { build(:chapter, slug: 'mumuki/t3') }

    let(:user) { create(:user) }
    let(:organization) { Organization.current }

    it { expect(AccessLevel.sort %i(hidden enabled disabled enabled hidden)).to eq %i(hidden hidden disabled enabled enabled) }
    it { expect(AccessLevel.min %i(hidden enabled disabled enabled hidden)).to eq :hidden }


    describe 'in organization' do
      let(:workspace) { Workspace.new user, organization }
      context 'no access rules' do
        it { expect(workspace.access_levels_for(book.chapters)).to eq chapter_1 => :enabled, chapter_2 => :enabled, chapter_3 => :enabled }

        it { expect(book.enabled_chapters_of(workspace)).to eq book.chapters }
        it { expect(book.chapter_access_levels_in(workspace)).to eq chapter_1 => :enabled, chapter_2 => :enabled, chapter_3 => :enabled }
      end

      context 'hide mumuki/t1' do
        let(:rule) { AccessRule::Always.new(content: chapter_1, action: :hide) }

        before { organization.add_access_rule! rule }

        it { expect(rule.to_s).to eq 'hide mumuki/t1' }
        it { expect(book.enabled_chapters_of(workspace)).to eq [chapter_2, chapter_3] }
        it { expect(book.chapter_access_levels_in(workspace)).to eq chapter_1 => :hidden, chapter_2 => :enabled, chapter_3 => :enabled }
      end

      context 'disable mumuki/t1' do
        let(:rule) { AccessRule::Always.new(content: chapter_1, action: :disable) }
        before { organization.add_access_rule! rule }

        it { expect(rule.to_s).to eq 'disable mumuki/t1' }
        it { expect(book.enabled_chapters_of(workspace)).to eq [chapter_2, chapter_3] }
        it { expect(book.chapter_access_levels_in(workspace)).to eq chapter_1 => :disabled, chapter_2 => :enabled, chapter_3 => :enabled }
      end

      context 'hide mumuki/t1 at 2020-10-10' do
        let(:rule) { AccessRule::At.new(content: chapter_2, action: :hide, date: date) }
        before { organization.add_access_rule! rule }

        context 'after date' do
          let(:date) { 5.minutes.ago }

          it { expect(rule.to_s).to eq "hide mumuki/t2 at #{date}" }
          it { expect(book.enabled_chapters_of(workspace)).to eq [chapter_1, chapter_3] }
          it { expect(book.chapter_access_levels_in(workspace)).to eq chapter_1 => :enabled, chapter_2 => :hidden, chapter_3 => :enabled }
        end

        context 'before date' do
          let(:date) { 5.minutes.since }

          it { expect(book.enabled_chapters_of(workspace)).to eq [chapter_1, chapter_2, chapter_3] }
          it { expect(book.chapter_access_levels_in(workspace)).to eq chapter_1 => :enabled, chapter_2 => :enabled, chapter_3 => :enabled }
        end
      end

      context 'disable mumuki/t1 until 2020-10-10' do
        let(:rule) { AccessRule::Until.new(content: chapter_2, action: :disable, date: date) }
        before { organization.add_access_rule! rule }


        context 'after date' do
          let(:date) { 5.minutes.ago }

          it { expect(rule.to_s).to eq "disable mumuki/t2 until #{date}" }
          it { expect(book.enabled_chapters_of(workspace)).to eq [chapter_1, chapter_2, chapter_3] }
          it { expect(book.chapter_access_levels_in(workspace)).to eq chapter_1 => :enabled, chapter_2 => :enabled, chapter_3 => :enabled }
        end

        context 'before date' do
          let(:date) { 5.minutes.since }

          it { expect(book.enabled_chapters_of(workspace)).to eq [chapter_1, chapter_3] }
          it { expect(book.chapter_access_levels_in(workspace)).to eq chapter_1 => :enabled, chapter_2 => :disabled, chapter_3 => :enabled }
        end
      end

      context 'hide mumuki/t1 unless teacher' do
        let(:rule) { AccessRule::Unless.new(content: chapter_3, action: :hide, role: :teacher) }
        before { organization.add_access_rule! rule }


        it { expect(rule.to_s).to eq 'hide mumuki/t3 unless teacher' }

        context 'with role' do
          before { user.add_permission! :teacher, organization.slug }

          it { expect(book.chapter_access_levels_in(workspace)).to eq chapter_1 => :enabled, chapter_2 => :enabled, chapter_3 => :enabled }
        end

        context 'with upper role' do
          before { user.add_permission! :headmaster, organization.slug }

          it { expect(book.chapter_access_levels_in(workspace)).to eq chapter_1 => :enabled, chapter_2 => :enabled, chapter_3 => :enabled }
        end

        context 'without roles' do
          it { expect(book.chapter_access_levels_in(workspace)).to eq chapter_1 => :enabled, chapter_2 => :enabled, chapter_3 => :hidden }
        end
      end
    end

    describe 'in course' do
      let(:course) { create(:course, organization: organization) }
      let(:workspace) { CourseWorkspace.new user, course }

      context 'no access rules' do
        it { expect(book.chapter_access_levels_in(workspace)).to eq chapter_1 => :enabled, chapter_2 => :enabled, chapter_3 => :enabled }
      end

      context 'hide mumuki/t1' do
        let(:rule) { AccessRule.compile 'hide mumuki/t1' }

        before { course.add_access_rule! rule }

        it { expect(book.chapter_access_levels_in(workspace)).to eq chapter_1 => :hidden, chapter_2 => :enabled, chapter_3 => :enabled }
      end
    end
  end

end
