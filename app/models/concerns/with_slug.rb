#TODO may use mumukit slug
module WithSlug
  extend ActiveSupport::Concern

  included do
    validates_presence_of :slug
    validates_uniqueness_of :slug
    before_create :normalize_slug!
  end

  def transparent_parms
    org, repo = slug.split('/')
    {organization: org, repository: repo}
  end

  def transparent_id
    slug
  end

  def normalize_slug!
    self.slug = self.slug.to_mumukit_slug.normalize.to_s
  end

  ## Copy and Rebase

  def rebase!(organization)
    self.slug = self.slug.to_mumukit_slug.rebase(organization).to_s
  end

  def rebased_dup(organization)
    dup.tap { |it| it.rebase! organization }
  end

  ## Filtering

  class_methods do

    def allowed(permissions)
      all.select { |it| permissions&.writer?(it.slug) }
    end

    def visible(permissions)
      # FIXME no truly generic
      all.select { |it| !it.private? || permissions&.writer?(it.slug) }
    end

    def find_transparently!(args)
      find_by!(slug: "#{args[:organization]}/#{args[:repository]}")
    end

    ## Resource Protocol

    def sync_key_id_field
      :slug
    end

    def locate_resource(key)
      find_or_initialize_by(slug: key)
    end
  end
end
