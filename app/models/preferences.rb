class Preferences
  include ActiveModel::Model

  def self.attributes
    [:uppercase_mode]
  end

  attr_accessor *self.attributes

  def self.from_attributes(*args)
    new self.attributes.zip(args).to_h
  end

  def uppercase?
    uppercase_mode
  end
end