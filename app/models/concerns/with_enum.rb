class Module
  def to_method_name
    name.demodulize.underscore
  end
end

module WithEnum
  extend ActiveSupport::Concern

  included do
    mattr_accessor :defined_enums
  end

  def self.define_enum_methods_for(klass)
    to_method_name = klass.to_instance_method_name
    String.send :define_method, to_method_name, proc { to_sym.send(to_method_name) }
    Symbol.send :define_method, to_method_name, proc { klass.from_sym self }
    klass.send(:define_method, to_method_name) { self }
    klass.enum_constants.each do |enum|
      enum.extend klass
      klass.enum_constants.each do |it|
        enum.define_singleton_method("#{it.to_method_name}?") { self == it }
      end
    end
  end

  def to_i
    parent.enum_constants.index(self)
  end

  def to_test_selector
    "#{to_method_name}?"
  end

  def to_sym
    to_s.to_sym
  end

  def to_s
    to_method_name
  end

  def ==(other)
    self.equal? parent.to_enum(other) rescue false
  end

  class_methods do
    def load(int)
      cast(int)
    end

    def dump(enum)
      if enum.is_a?(Numeric) || enum.to_s.match(/^\d+$/)
        enum.to_i
      else
        to_enum(enum).to_i
      end
    end

    def to_enum(enum_name)
      enum_name.send(to_instance_method_name)
    end

    def to_instance_method_name
      "to_#{to_method_name}"
    end

    def test_selectors
      enum_constants.map(&:to_test_selector)
    end

    def from_sym(enum_name)
      "#{module_namespace(self)}::#{module_namespace(enum_name)}".constantize
    end

    def module_namespace(mod)
      mod.to_s.camelize
    end

    def cast(i)
      enum_constants.find { |it| it.to_i == i.to_i } if i.present?
    end

    def enum_constants
      @enum_constants ||= defined_enums.map { |enum| from_sym enum }
    end
  end
end

