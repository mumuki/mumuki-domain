
require_relative '../spec_helper'
describe Mumukit::Sync::Store::Thesaurus do
  describe 'read_resource' do
    let(:bridge) { Mumukit::Bridge::Thesaurus.new('http://thesaurus.com') }
    let(:store) { Mumukit::Sync::Store::Thesaurus.new bridge }
    let(:sync_key) { struct kind: :language, id: 'http://rubyrunner.com' }

    let(:runner_response) { {
      'name' => 'ruby',
      'version' => 'master',
      'escualo_base_version' => nil,
      'escualo_service_version' => nil,
      'mumukit_version' => '1.0.1',
      'output_content_type' => 'markdown',
      'features' => {
          'query' => true,
          'expectations' => false,
          'feedback' => false,
          'secure' => false,
          'sandboxed' => true,
          'stateful' => true,
          'structured' => true
      },
      'language' => {
          'prompt' => '>',
          'name' => 'ruby',
          'version' => '2.0',
          'extension' => 'rb',
          'ace_mode' => 'ruby'
      },
      'test_framework' => {
          'name' => 'rspec',
          'version' => '2.13',
          'test_extension' => '.rb'
      },
      'url' => 'http://rubyrunner.com/info'
    } }

    before do
      expect_any_instance_of(Mumukit::Bridge::Runner).to receive(:info).and_return runner_response
    end

    it { expect(store.read_resource(sync_key)).to json_eq name: "ruby",
                                                          comment_type: nil,
                                                          runner_url: "http://rubyrunner.com",
                                                          output_content_type: "markdown",
                                                          prompt: "> ",
                                                          extension: "rb",
                                                          highlight_mode: "ruby",
                                                          visible_success_output: false,
                                                          devicon: nil,
                                                          triable: false,
                                                          feedback: false,
                                                          queriable: true,
                                                          stateful_console: true,
                                                          test_extension: ".rb",
                                                          test_template: nil,
                                                          layout_js_urls: [],
                                                          layout_html_urls: [],
                                                          layout_css_urls: [],
                                                          editor_js_urls: [],
                                                          editor_html_urls: [],
                                                          editor_css_urls: [],
                                                          multifile: false,
                                                          layout_shows_loading_content: false,
                                                          editor_shows_loading_content: false }
  end
end
