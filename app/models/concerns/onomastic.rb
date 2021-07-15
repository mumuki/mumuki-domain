module Onomastic
  extend ActiveSupport::Concern

  included do
    alias_method :name, :full_name
  end

  def formal_first_name
    verified_first_name.presence || first_name
  end

  def formal_last_name
    verified_last_name.presence || last_name
  end

  def has_verified_full_name?
    verified_first_name? && verified_last_name?
  end

  def formal_full_name
    join_names formal_first_name, formal_last_name
  end

  def full_name
    join_names first_name, last_name
  end

  def verified_full_name
    join_names verified_first_name, verified_last_name
  end

  private

  def join_names(first, last)
    "#{first} #{last}".strip
  end
end
