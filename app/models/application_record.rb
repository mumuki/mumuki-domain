class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  delegate :whitelist_attributes, to: :class

  def self.teaser_on(*args)
    args.each do |selector|
      teaser_selector = "#{selector}_teaser"
      define_method teaser_selector do
        send(selector)&.markdown_paragraphs&.first
      end
      markdown_on teaser_selector, skip_sanitization: true
    end
  end

  def self.defaults(&block)
    after_initialize :defaults, if: :new_record?
    define_method :defaults, &block
  end

  def self.all_except(others)
    if others.present?
      where.not(id: [others.map(&:id)])
    else
      all
    end
  end

  def self.serialize_symbolized_hash_array(*keys)
    keys.each do |field|
      serialize field
      define_method(field) { self[field]&.map { |it| it.deep_symbolize_keys } }
    end
  end

  def save(*)
    super
  rescue => e
    self.errors.add :base, e.message
    self
  end

  def save_and_notify_changes!
    if changed?
      save_and_notify!
    else
      save!
    end
  end

  def destroy!
    super
  rescue ActiveRecord::RecordNotDestroyed => e
    errors[:base].last.try { |it| raise ActiveRecord::RecordNotDestroyed.new it }
    raise e
  rescue ActiveRecord::InvalidForeignKey => e
    raise_foreign_key_error!
  end

  def delete
    super
  rescue ActiveRecord::InvalidForeignKey => e
    raise_foreign_key_error!
  end

  def save_and_notify!
    save!
    notify!
    self
  end

  def update_and_notify!(data)
    assign_attributes data
    save_and_notify!
  end

  def self.aggregate_of(association)
    class_eval do
      define_method("rebuild_#{association}!") do |children|
        transaction do
          self.send(association).all_except(children).destroy_all
          self.update! association => children
          children.each &:save!
        end
        reload
      end
    end
  end

  def self.with_temporary_token(field_name, duration = 2.hours)
    class_eval do
      token_attribute = field_name
      token_date_attribute = "#{field_name}_expiration_date"

      define_method("generate_#{field_name}!") do
        update!(token_attribute => self.class.generate_secure_token, token_date_attribute => duration.from_now)
      end

      define_method("#{field_name}_matches?") do |token|
        actual_token = attribute(token_attribute)
        actual_token.present? && token == actual_token && attribute(token_date_attribute)&.future?
      end
    end
  end

  def self.numbered(*associations)
    class_eval do
      associations.each do |it|
        define_method("#{it}=") do |e|
          e.merge_numbers!
          super(e)
        end
      end
    end
  end

  def self.update_or_create!(attributes)
    obj = first || new
    obj.update!(attributes)
    obj
  end

  def self.whitelist_attributes(a_hash, options = {})
    attributes = attribute_names
    attributes += reflections.keys if options[:relations]
    a_hash.with_indifferent_access.slice(*attributes).except(*options[:except])
  end

  def self.organic_on(*selectors)
    selectors.each do |selector|
      define_method("#{selector}_in_organization") do |organization = Organization.current|
        send(selector).where(organization: organization)
      end
    end
  end

  def self.active_between(start_date_field, end_date_field, **options)
    define_singleton_method(:active) do |actually_filter=true|
      if actually_filter
        self.where("(#{start_date_field} IS NULL OR #{start_date_field} < :now) AND (#{end_date_field} IS NULL OR #{end_date_field} > :now)", now: Time.now)
      else
        all
      end
    end

    aliased_as = options.delete(:aliased_as)
    singleton_class.send(:alias_method, aliased_as, :active) if aliased_as
  end

  ## Partially implements resource-hash protocol, by
  ## defining `to_resource_h` and helper methods `resource_fields` and `slice_resource_h`
  ## using the given fields
  def self.resource_fields(*fields)
    include Mumuki::Domain::Syncable::WithResourceFields

    define_singleton_method :resource_fields do
      fields
    end
  end

  def self.enum_prefixed_translations_for(selector)
    send(selector.to_s.pluralize).map do |key, _|
      [I18n.t("#{selector}_#{key}", default: key.to_sym), key]
    end
  end

  private

  def raise_foreign_key_error!
    raise ActiveRecord::InvalidForeignKey.new "#{model_name} is still referenced"
  end

  def self.generate_secure_token
    SecureRandom.base58(24)
  end
end
