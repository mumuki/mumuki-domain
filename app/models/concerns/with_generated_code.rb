module WithGeneratedCode
  extend ActiveSupport::Concern

  included do
    validates_uniqueness_of :code

    defaults do
      self.code ||= self.class.generate_code
    end

    required :code_size
  end

  class_methods do
    def generate_code
      SecureRandom.urlsafe_base64 code_size
    end
  end
end