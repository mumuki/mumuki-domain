module Mumuki::Domain::Access
  class Config
    attr_accessor :rules, :source, :owner

    def initialize(source, owner)
      @source = source
      @owner = owner
      @rules = []
    end

    # todo recompile when reindenxing
    def compile!
      ast = Mumuki::Domain::Access::ConfigParser.new.parse source
      ast.each { |line| compile_line! line }
    end

    def compile_line!(line)
      klass = line.delete :class
      grant = line.delete :grant
      rules.push(*select_contents(grant).map { |it| build_rule klass, line, it })
    end

    def build_rule(klass, ast, content)
      klass.new(ast.merge content: content, owner: owner)
    end

    def select_contents(grant)
      owner.book.chapters.select { |it| grant.allows? it.slug }
    end

    def self.compile(source, owner)
      config = Mumuki::Domain::Access::Config.new(source, owner)
      config.compile!
      config.rules
    end
  end
end
