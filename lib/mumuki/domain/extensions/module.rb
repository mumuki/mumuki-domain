#TODO move to mumukit-core
class Module
  def ensure_defined!(selector)
    # FIXME pass additional false flag in ruby 2.6
    raise "method #{selector} was not previously defined here" unless method_defined?(selector)
  end

  def ensure_undefined!(selector)
    # FIXME pass additional false flag in ruby 2.6
    raise "method #{selector} was previously defined here" if method_defined?(selector)
  end

  def define_once(selector, *args, **named, &block)
    ensure_undefined! selector
    define_method selector, *args, **named, &block
  end
end
