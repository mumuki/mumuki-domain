require_relative '../spec_helper'



class AccessConfig
  attr_accessor :rules, :source, :organization

  def initialize(source, organization)
    @source = source
    @organization = organization
    @rules = []
  end

  # todo recompile when reindenxing
  def compile!
    ast = Mumuki::Domain::Parsers::AccessRuleParser.new.parse source
    ast.each { |line| compile_line! line }
  end

  def compile_line!(line)
    klass = line.delete :class
    grant = line.delete :grant
    rules.push(*select_contents(grant).map { |it| build_rule klass, line, it })
  end

  def build_rule(klass, ast, content)
    klass.new(ast.merge content: content, organization: organization)
  end

  def select_contents(grant)
    organization.book.chapters.select { |it| grant.allows? it.slug }
  end

  def self.compile(source, organization = Organization.current)
    config = AccessConfig.new(source, organization)
    config.compile!
    config.rules
  end
end


describe AccessConfig, organization_workspace: :test do
  describe 'compile' do
    let(:organization) { Organization.current }
    let!(:chapter_1) { create(:chapter, slug: 'foo/bar') }
    let!(:chapter_2) { create(:chapter, slug: 'foo/baz') }
    let!(:chapter_3) { create(:chapter, slug: 'foobar/baz') }

    before { reindex_current_organization! }

    it { expect(AccessConfig.compile('hide "foo/bar" until "2020-10-20";').map(&:class)).to eq [AccessRule::Until] }
    it { expect(AccessConfig.compile('disable "foo/baz" unless teacher;').map(&:class)).to eq [AccessRule::Unless] }
    it { expect(AccessConfig.compile('disable "foo/*" while unready;').map(&:class)).to eq [AccessRule::WhileUnready,AccessRule::WhileUnready] }

  end
end
