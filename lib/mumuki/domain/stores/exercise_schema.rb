module Mumukit::Sync::Store::Github::Schema::Exercise
  extend Mumukit::Sync::Store::Github::Schema

  def self.fields_schema
    [
      {name: :id, kind: :special},
      {name: :name, kind: :special},

      {name: :tags, kind: :metadata, reverse: :tag_list, transform: with { |it| it.to_a }},
      {name: :layout, kind: :metadata},
      {name: :editor, kind: :metadata},

      {name: :type, kind: :metadata},
      {name: :extra_visible, kind: :metadata},
      {name: :language, kind: :metadata, transform: name },
      {name: :teacher_info, kind: :metadata},
      {name: :manual_evaluation, kind: :metadata},
      {name: :choices, kind: :metadata},

      {name: :expectations,     kind: :file, extension: 'yml', transform: yaml_list('expectations')},
      {name: :assistance_rules, kind: :file, extension: 'yml', transform: yaml_list('rules')},
      {name: :randomizations,   kind: :file, extension: 'yml', transform: yaml_hash},

      {name: :goal, kind: :metadata},
      {name: :test, kind: :file, extension: :test},
      {name: :extra, kind: :file, extension: :code},
      {name: :default, kind: :file, extension: :code, reverse: :default_content},

      {name: :description, kind: :file, extension: 'md', required: true},
      {name: :hint, kind: :file, extension: 'md'},
      {name: :corollary, kind: :file, extension: 'md'},
      {name: :initial_state, kind: :file, extension: 'md'},
      {name: :final_state, kind: :file, extension: 'md'},
      {name: :free_form_editor_source, kind: :file, extension: 'html'}
    ]
  end
end
