require 'spec_helper'

describe Usage do

  let!(:fundamentals) { create(:topic) }
  let!(:functional_programming) { create(:topic) }
  let!(:oop) { create(:topic) }
  let!(:logic_programming) { create(:topic) }

  let!(:programming) { create(:book, chapters: [
      build(:chapter, topic: fundamentals),
      build(:chapter, topic: functional_programming),
      build(:chapter, topic: oop),
      build(:chapter, topic: logic_programming),
  ]) }

  let!(:paradigms) { create(:book, chapters: [
      build(:chapter, topic: functional_programming),
      build(:chapter, topic: logic_programming),
      build(:chapter, topic: oop),
  ]) }

  let!(:central) { create(:organization, name: 'central', book: programming) }
  let!(:pdep) { create(:organization, name: 'pdep', book: paradigms) }

  shared_examples_for 'something that does not interfere with normal scopes' do
    it 'does not affect all-scope' do
      expect(Topic.all.count).to eq 4
      expect(Chapter.all.count).to eq 7
      expect(Book.all.count).to eq 2
      expect(Organization.all.count).to eq 2
    end
  end

  context 'on central' do
    before { central.switch! }

    it_behaves_like 'something that does not interfere with normal scopes'

    it { expect(central.book).to eq programming }

    it { expect(programming.chapters.count).to eq 4 }
    it { expect(programming.chapters.map(&:topic)).to eq [fundamentals, functional_programming, oop, logic_programming] }

    it 'usage_in_organization behaves properly' do
      expect(fundamentals.usage_in_organization).to_not be_nil
      expect(fundamentals.usage_in_organization.number).to eq 1

      expect(functional_programming.usage_in_organization).to_not be_nil
      expect(functional_programming.usage_in_organization).to be_a(Chapter)
      expect(functional_programming.usage_in_organization.number).to eq 2
      expect(oop.usage_in_organization.number).to eq 3
      expect(logic_programming.usage_in_organization.number).to eq 4
    end

    it { expect(Usage.in_organization.count).to eq 5  }

  end

  context 'on pdep' do
    before { pdep.switch! }

    it_behaves_like 'something that does not interfere with normal scopes'

    it { expect(pdep.book).to eq paradigms }

    it { expect(paradigms.chapters.count).to eq 3 }
    it { expect(paradigms.chapters.map(&:topic)).to eq [functional_programming, logic_programming, oop] }

    it 'usage_in_organization behaves properly' do
      expect(fundamentals.usage_in_organization).to be_nil

      expect(functional_programming.usage_in_organization).to_not be_nil
      expect(functional_programming.usage_in_organization).to be_a(Chapter)
      expect(functional_programming.usage_in_organization.number).to eq 1
      expect(logic_programming.usage_in_organization.number).to eq 2
      expect(oop.usage_in_organization.number).to eq 3
    end

    it { expect(Usage.in_organization.count).to eq 4  }
  end
end
