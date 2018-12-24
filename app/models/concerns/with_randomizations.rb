module WithRandomizations
  extend ActiveSupport::Concern

  included do
    serialize :randomizations, Hash
    validate :ensure_randomizations_format
  end

  def randomizer
    #TODO remove this hack after removing seed state from here
    @randomizer ||= (Mumukit::Randomizer.parse(randomizations) rescue Mumukit::Randomizer.new([]))
  end

  private

  def ensure_randomizations_format
    errors.add :randomizations,
               :invalid_format unless Mumukit::Randomizer.valid? randomizations.to_h
  end
end
