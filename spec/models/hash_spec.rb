require 'spec_helper'

describe Hash do
  describe 'markdownified!' do
    let(:hash) { { something: 'hello **world**', something_else: '`the code`', other: '_foo_' } }

    context 'without options' do
      before { hash.markdownified! :something, :something_else }
      it { expect(hash).to eq other: "_foo_", something: "<p>hello <strong>world</strong></p>\n", something_else: "<p><code>the code</code></p>\n" }
    end

    context 'with options' do
      before { hash.markdownified! :something, :something_else, one_liner: true }
      it { expect(hash).to eq other: "_foo_", something: "hello <strong>world</strong>", something_else: "<code>the code</code>" }
    end
  end
end
