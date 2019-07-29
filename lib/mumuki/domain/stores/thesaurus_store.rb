module Mumukit::Sync::Store

  ## This Store enables importing languages
  ## from Thesaurus API
  class Thesaurus < Mumukit::Sync::Store::Base
    def initialize(thesaurus_bridge)
      @thesaurus_bridge = thesaurus_bridge
    end

    def sync_keys
      @thesaurus_bridge.runners.map { |it| Mumukit::Sync.key(:language, it) }
    end

    def do_read(sync_key)
      return unless sync_key.kind.like? :language
      transform_after_read(sync_key.id, Mumukit::Bridge::Runner.new(sync_key.id).info)
    end

    def transform_after_read(runner_url, info)
      Mumukit::Sync::Store::Thesaurus::InfoConverter.new(runner_url, info).call
    end

    def write_resource!(*)
      Mumukit::Sync::Store.read_only!
    end

    class InfoConverter
      def initialize(runner_url, info)
        @runner_url = runner_url
        @info = info
      end

      def call
        {
          name:                         @info['name'],
          comment_type:                 @info['comment_type'],
          runner_url:                   @runner_url,
          output_content_type:          @info['output_content_type'],
          prompt:                       (@info.dig('language', 'prompt') || 'ム') + ' ',
          extension:                    @info.dig('language', 'extension'),
          highlight_mode:               @info.dig('language', 'ace_mode'),
          visible_success_output:       @info.dig('language', 'graphic').present?,
          devicon:                      @info.dig('language', 'icon', 'name'),
          triable:                      @info.dig('features', 'try').present?,
          feedback:                     @info.dig('features', 'feedback').present?,
          queriable:                    @info.dig('features', 'query').present?,
          stateful_console:             @info.dig('features', 'stateful').present?,
          multifile:                    @info.dig('features', 'multifile').present?,
          settings:                     @info.dig('features', 'settings').present?,
          test_extension:               @info.dig('test_framework', 'test_extension'),
          test_template:                @info.dig('test_framework', 'template'),
          layout_js_urls:               get_assets_for(:layout, 'js'),
          layout_html_urls:             get_assets_for(:layout, 'html'),
          layout_css_urls:              get_assets_for(:layout, 'css'),
          editor_js_urls:               get_assets_for(:editor, 'js'),
          editor_html_urls:             get_assets_for(:editor, 'html'),
          editor_css_urls:              get_assets_for(:editor, 'css'),
          layout_shows_loading_content: shows_loading_content_for?(:layout),
          editor_shows_loading_content: shows_loading_content_for?(:editor)
        }
      end

      def get_assets_for(kind, content_type)
        absolutize(get_asset_field(kind, content_type) || [])
      end

      def get_asset_field(kind, field)
        @info.dig("#{kind}_assets_urls", field)
      end

      def absolutize(urls)
        urls.map { |url| "#{@runner_url}/#{url}"}
      end

      def shows_loading_content_for?(kind)
        get_asset_field(kind, 'shows_loading_content').present?
      end
    end
  end
end
