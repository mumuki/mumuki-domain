require 'spec_helper'

describe Hash do
  describe 'markdown_paragraphs' do
    let(:hash) { { something: 'hello **world**', something_else: '`the code`', other: '_foo_' } }

    before { hash.markdownify! :something, :something_else }

    it { expect(hash).to eq other: "_foo_", something: "<p>hello <strong>world</strong></p>\n", something_else: "<p><code>the code</code></p>\n" }
  end
end
