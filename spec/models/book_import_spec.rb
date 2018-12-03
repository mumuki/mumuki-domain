require 'spec_helper'

describe Book do
  let!(:haskell) { create(:haskell) }
  let!(:gobstones) { create(:gobstones) }

  let!(:guide_1) { create(:guide, name: 'a lesson') }
  let!(:guide_2) { create(:guide, name: 'other lesson') }

  let!(:topic_1) { create(:topic, name: 'a topic') }
  let!(:topic_2) { create(:topic, name: 'other topic') }


  let(:book_resource_h) do
    {name: 'sample book',
      description: 'a sample book description',
      slug: 'mumuki/a-book',
      locale: 'en',
      chapters: [topic_1.slug, topic_2.slug],
      complements: complement_slugs,
    }
  end

  let(:complement_slugs) { [] }

  describe '#sync_key' do
    let(:book) { create(:book, slug: 'mumuki/a-book') }

    it { expect(book.sync_key).to eq Mumukit::Sync.key(Book, 'mumuki/a-book')}
  end

  describe '.import_from_resource_h!' do
    let(:book) { Book.import_from_resource_h! book_resource_h }

    it { expect(book.sync_key).to eq Mumukit::Sync.key(Book, 'mumuki/a-book') }
  end

  describe '#import_from_resource_h!', organization_workspace: :test do
    let(:book) { Organization.current.book }

    context 'when complements are present' do
      let(:complement_slugs) { [guide_2.slug, guide_1.slug] }

      before { book.import_from_resource_h!(book_resource_h) }

      it { expect(book.name).to eq 'sample book' }
      it { expect(book.description).to eq 'a sample book description' }
      it { expect(book.locale).to eq 'en' }
      it { expect(book.chapters.count).to eq 2 }
      it { expect(book.complements.count).to eq 2 }

      it { expect(topic_2.reload.usage_in_organization).to be_a Chapter }
      it { expect(guide_2.reload.usage_in_organization).to be_a Complement }

      it { expect(book.sync_key).to eq Mumukit::Sync.key(Book, 'mumuki/a-book') }
    end

    context 'when complements are not present' do
      let(:complement_slugs) { ['foo/bar', guide_1.slug] }

      before { book.import_from_resource_h!(book_resource_h) }

      it { expect(book.complements.count).to eq 1 }
    end
  end
end
