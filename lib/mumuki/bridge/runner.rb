module Mumukit
  module Bridge
    class Runner
      def importable_info(headers={})
        @language_json ||= info(headers).merge('url' => test_runner_url)
        {
          name:                         @language_json['name'],
          comment_type:                 @language_json['comment_type'],
          test_runner_url:              @language_json['url'],
          output_content_type:          @language_json['output_content_type'],
          prompt:                       (@language_json.dig('language', 'prompt') || 'ム') + ' ',
          extension:                    @language_json.dig('language', 'extension'),
          highlight_mode:               @language_json.dig('language', 'ace_mode'),
          visible_success_output:       @language_json.dig('language', 'graphic').present?,
          devicon:                      @language_json.dig('language', 'icon', 'name'),
          triable:                      @language_json.dig('features', 'try').present?,
          feedback:                     @language_json.dig('features', 'feedback').present?,
          queriable:                    @language_json.dig('features', 'query').present?,
          stateful_console:             @language_json.dig('features', 'stateful').present?,
          multifile:                    @language_json.dig('features', 'multifile').present?,
          test_extension:               @language_json.dig('test_framework', 'test_extension'),
          test_template:                @language_json.dig('test_framework', 'template'),
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
        @language_json.dig("#{kind}_assets_urls", field)
      end

      def absolutize(urls)
        urls.map { |url| "#{test_runner_url}/#{url}"}
      end

      def shows_loading_content_for?(kind)
        get_asset_field(kind, 'shows_loading_content').present?
      end
    end
  end
end
