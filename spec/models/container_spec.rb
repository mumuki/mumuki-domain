require 'spec_helper'

describe Container do

  let!(:fundamentals) { create(:topic) }
  let!(:functional_programming) { create(:topic) }
  let!(:oop) { create(:topic) }
  let!(:logic_programming) { create(:topic) }

  let(:fundamentals_chapter) { build(:chapter, topic: fundamentals) }
  let(:functional_chapter_programming) { build(:chapter, topic: functional_programming) }
  let(:functional_chapter_paradigms) { build(:chapter, topic: functional_programming) }

  let!(:programming) { create(:book, chapters: [
      fundamentals_chapter,
      functional_chapter_programming,
      build(:chapter, topic: oop),
      build(:chapter, topic: logic_programming),
  ]) }

  let!(:paradigms) { create(:book, chapters: [
      functional_chapter_paradigms,
      build(:chapter, topic: logic_programming),
      build(:chapter, topic: oop),
  ]) }

  let!(:central) { create(:organization, name: 'central', book: programming) }
  let!(:pdep) { create(:organization, name: 'pdep', book: paradigms) }

  context '#navigable_content_in' do
    it { expect(functional_chapter_programming.navigable_content_in(pdep)).to eq(functional_chapter_paradigms) }
    it { expect(fundamentals_chapter.navigable_content_in(pdep)).to be_nil }
  end

  context '#content_used_in?' do
    it { expect(functional_chapter_programming.content_used_in?(pdep)).to be_truthy }
    it { expect(fundamentals_chapter.content_used_in?(pdep)).to be_falsey }
  end
end
