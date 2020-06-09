module TopicContainer
  extend ActiveSupport::Concern
  include Container

  included do
    associated_content :topic

    delegate :name,
             :slug,
             :appendix,
             :appendix_html,
             :description,
             :description_html,
             :description_teaser_html,
             :rebuild_lessons!,
             :lessons,
             :guides,
             :pending_guides,
             :lessons,
             :first_lesson,
             :locale,
             :exercises, to: :topic
  end
end
