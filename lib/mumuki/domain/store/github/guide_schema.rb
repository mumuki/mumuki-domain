module Mumuki::Domain::Store::Github::GuideSchema
  extend Mumukit::Sync::Store::Github::Schema

  def self.fields_schema
    [
      {name: :exercises, kind: :special},
      {name: :id, kind: :special},
      {name: :slug, kind: :special},

      {name: :name, kind: :metadata},
      {name: :locale, kind: :metadata},
      {name: :type, kind: :metadata},
      {name: :beta, kind: :metadata},
      {name: :teacher_info, kind: :metadata},
      {name: :language, kind: :metadata, transform: name },
      {name: :id_format, kind: :metadata},
      {name: :order, kind: :metadata, transform: with { |it| it.map { |e| e[:id] } }, reverse: :exercises},
      {name: :private, kind: :metadata},

      {name: :expectations,        kind: :file, extension: 'yml', transform: yaml_list('expectations')},
      {name: :custom_expectations, kind: :file, extension: 'edl'},
      {name: :settings,            kind: :file, extension: 'yml', transform: yaml_hash},

      {name: :description, kind: :file, extension: 'md', required: true},
      {name: :corollary, kind: :file, extension: 'md'},
      {name: :sources, kind: :file, extension: 'md'},
      {name: :learn_more, kind: :file, extension: 'md'},
      {name: :extra, kind: :file, extension: :code},
      {name: :AUTHORS, kind: :file, extension: 'txt', reverse: :authors},
      {name: :COLLABORATORS, kind: :file, extension: 'txt', reverse: :collaborators}
    ]
  end

  def self.fixed_file_patterns
    %w(LICENSE.txt README.md COPYRIGHT.txt meta.yml *_*/*)
  end
end
