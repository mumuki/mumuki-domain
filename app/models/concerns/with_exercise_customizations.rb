
# Exercises effective fields from a student's perspective
# do not match exactly their true content, but are customized
# by guide's _accumulative fields_, _interpolations_ and _randomizations_ instead.
#
# These customizations are compatible with the `Contextualization` mixin.
module WithExerciseCustomizations
  # TODO: move this code into mumukit-core
  def self.patch_accessor(*selectors, &block)
    selectors.each do |selector|
      patch(selector) do |hyper|
        result = hyper.call
        result && instance_exec(result, &block)
      end
    end
  end

  delegate :description, :test, :hint, :default_content, to: :exercise

  ## Accumulation

  def extra
    exercise.accumulated_extra
  end

  def expectations
    exercise.accumulated_expectations
  end

  ## Interpolation

  def self.interpolate(*selectors)
    patch_accessor(*selectors) do |attr|
      self.language.interpolate_references_for self, attr
    end
  end

  interpolate :test, :extra

  ## Randomization

  delegate :randomizer, to: :exercise

  def seed
    @seed || 0
  end

  def seed_with!(seed)
    @seed = seed
  end

  def self.randomize(*selectors)
    patch_accessor(*selectors) do |attr|
      randomizer.randomize! attr, seed
    end
  end

  randomize :description, :hint, :extra, :test, :default_content

  ## Contextualization

  def extra_preview
    Mumukit::ContentType::Markdown.highlighted_code(language.name, extra)
  end

  # required by `Contextualization`
  markdown_on :extra_preview
end
