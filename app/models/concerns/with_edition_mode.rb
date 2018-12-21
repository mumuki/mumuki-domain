module WithEditionMode
  extend ActiveSupport::Concern

  attr_accessor :edition_mode

  def edit!
    self.edition_mode = true
  end

  module ClassMethods
    def editable(*selectors)
      selectors.each { |selector| editable_field selector }
    end

    private

    def editable_field(selector)
      patch selector do |*args, hyper|
        edition_mode ? self[selector] : hyper.(*args)
      end
    end
  end
end
