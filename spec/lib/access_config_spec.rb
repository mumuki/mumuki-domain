require_relative '../spec_helper'

describe Mumuki::Domain::Access::Config, organization_workspace: :test do
  describe 'compile' do
    let(:organization) { Organization.current }
    let!(:chapter_1) { create(:chapter, slug: 'foo/bar') }
    let!(:chapter_2) { create(:chapter, slug: 'foo/baz') }
    let!(:chapter_3) { create(:chapter, slug: 'foobar/baz') }

    before { reindex_current_organization! }

    let(:compiled_classes) { Mumuki::Domain::Access::Config.compile(source, organization).map(&:class) }

    context 'one rule' do
      let(:source) { 'hide "foo/bar" until "2020-10-20";' }
      it { expect(compiled_classes).to eq [AccessRule::Until] }
    end

    context 'one rule without args' do
      let(:source) { 'disable "foo/baz"' }
      it { expect(compiled_classes).to eq [AccessRule::Always] }
    end

    context 'two rules' do
      let(:source) { 'disable "foo/*" while unready;' }
      it { expect(compiled_classes).to eq [AccessRule::WhileUnready,AccessRule::WhileUnready] }
    end
  end
end
