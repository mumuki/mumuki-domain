require_relative '../spec_helper'

describe AccessRule, organization_workspace: :test do
  describe 'compile' do
    let(:organization) { Organization.current }
    let!(:chapter_1) { create(:chapter, slug: 'foo/bar') }
    let!(:chapter_2) { create(:chapter, slug: 'foo/baz') }
    let!(:chapter_3) { create(:chapter, slug: 'foobar/baz') }

    before { reindex_current_organization! }

    it { expect(AccessRule.compile 'hide "foo/bar" until "2020-10-20"').to eq [AccessRule::Until.new(content: chapter_1, date: DateTime.new(2020, 10, 20), action: :hide, organization: organization)] }
    it { expect(AccessRule.compile 'disable "foo/baz" unless teacher').to eq [AccessRule::Unless.new(content: chapter_2, role: :teacher, action: :disable, organization: organization)] }
    it { expect(AccessRule.compile 'disable "foo/*" while unready').to eq [
                                                                        AccessRule::WhileUnready.new(content: chapter_1, action: :disable, organization: organization),
                                                                        AccessRule::WhileUnready.new(content: chapter_2, action: :disable, organization: organization)] }

  end
end
