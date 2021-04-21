require_relative '../spec_helper'

describe Mumukit::Platform::Organization do
  let(:organization) do
    Organization.new(
      name: 'orga',
      profile:  Mumuki::Domain::Organization::Profile.new(
                  community_link: 'http://link/to/community',
                  terms_of_service: 'The TOS',
                  description: 'the description'),
      settings: Mumuki::Domain::Organization::Settings.new(immersive: true),
      theme:    Mumuki::Domain::Organization::Theme.new(theme_stylesheet: 'css', extension_javascript: 'js'),
      book:     Book.new(slug: 'the/book'))
  end

  let(:json) do
    { name: 'test-orga',
      id: 998,
      settings: {
        feedback_suggestions_enabled: true,
        raise_hand_enabled: true,
        forum_enabled: true,
        forum_only_for_trusted: true,
        report_issue_enabled: true,
        teacher_training: true,
        public: false,
        gamification_enabled: true,
        immersive: false,
        in_preparation_until: 1.minute.ago,
        disabled_from: 1.minute.ago,
        login_methods: %w{facebook twitter google},
        login_provider: 'google',
        login_provider_settings: { token: '123' }
      },
      profile: {
        contact_email: 'issues@mumuki.io',
        description: 'Academy',
        terms_of_service: 'TOS',
        logo_url: 'http://mumuki.io/logo-alt-large.png',
        locale: 'en'
      },
      theme: {
        theme_stylesheet: '.foo { }',
        extension_javascript: 'function foo() { }'
      }
    }
  end
  let(:images_url_json) do
    { logo_url: 'http://mumuki.io/new-logo.png',
      favicon_url: 'http://mumuki.io/new-favicon.png',
      breadcrumb_image_url: 'http://mumuki.io/new-breadcrumb-image.png',
      open_graph_image_url: 'http://mumuki.io/new-og-image.png' }
  end

  it { expect(organization.platform_event_name(:created)).to eq 'OrganizationCreated' }
  it { expect(organization.as_platform_event).to eq organization: organization.to_resource_h }

  describe '#current' do
    context 'when switched' do
      before { Mumukit::Platform::Organization.switch! organization }
      it { expect(Mumukit::Platform::Organization.current?).to be true }
      it { expect(Mumukit::Platform::Organization.current).to eq organization }
      it { expect(Mumukit::Platform.current_organization_name).to eq 'orga' }
    end
    context 'when not switched' do
      before { Mumukit::Platform::Organization.leave! }
      it { expect(Mumukit::Platform::Organization.current?).to be false }
      it { expect { Mumukit::Platform::Organization.current }.to raise_error('organization not selected') }
      it { expect { Mumukit::Platform.current_organization_name }.to raise_error('organization not selected') }
    end
  end

  describe 'json conversion' do
    describe Mumuki::Domain::Organization::Settings do
      describe 'boolean accessors' do
        it { expect(Mumuki::Domain::Organization::Settings.new(public: true)).to be_public }
        it { expect(Mumuki::Domain::Organization::Settings.new(public: 'true')).to be_public }
        it { expect(Mumuki::Domain::Organization::Settings.new(public: false)).to_not be_public }
        it { expect(Mumuki::Domain::Organization::Settings.new(public: nil)).to_not be_public }
        it { expect(Mumuki::Domain::Organization::Settings.new(public: 'false')).to_not be_public }
        it { expect(Mumuki::Domain::Organization::Settings.new(public: 1)).to be_public }
        it { expect(Mumuki::Domain::Organization::Settings.new(public: 0)).to_not be_public }
        it { expect(Mumuki::Domain::Organization::Settings.new(public: '1')).to be_public }
        it { expect(Mumuki::Domain::Organization::Settings.new(public: '0')).to_not be_public }
      end

      describe '.parse' do
        subject { Mumuki::Domain::Organization::Settings.parse(json[:settings]) }

        it { expect(subject.login_methods).to eq %w{facebook twitter google} }
        it { expect(subject.login_provider).to eq 'google' }
        it { expect(subject.forum_discussions_minimal_role).to be :student }
        it { expect(subject.login_provider_settings).to eq(token: '123') }
        it { expect(subject.raise_hand_enabled?).to be true }
        it { expect(subject.report_issue_enabled?).to be true }
        it { expect(subject.forum_enabled?).to be true }
        it { expect(subject.forum_only_for_trusted?).to be true }
        it { expect(subject.feedback_suggestions_enabled?).to be true }
        it { expect(subject.public?).to eq false }
        it { expect(subject.gamification_enabled?).to be true }
        it { expect(subject.embeddable?).to eq false }
        it { expect(subject.immersive?).to eq false }
        it { expect(subject.disabled?).to eq true }
        it { expect(subject.in_preparation?).to eq false }
        it { expect(subject.teacher_training?).to eq true }

        it { expect(Mumuki::Domain::Organization::Settings.parse(nil)).to be_empty }
      end
      describe '.load' do
        let(:settings) { Mumuki::Domain::Organization::Settings.new(
                            public: true,
                            embeddable: true,
                            in_preparation_until: 1.minute.since,
                            disabled_from: 1.minute.since,
                            immersive: true,
                            raise_hand_enabled: false,
                            report_issue_enabled: false,
                            forum_enabled: false,
                            forum_only_for_trusted: false,
                            forum_discussions_minimal_role: 'teacher',
                            gamification_enabled: false,
                            login_methods: [:google]) }
        let(:dump) { Mumuki::Domain::Organization::Settings.dump(settings) }

        subject { Mumuki::Domain::Organization::Settings.load(dump) }

        it { expect(subject.login_methods).to eq %w{google} }
        it { expect(subject.forum_discussions_minimal_role).to be :teacher }
        it { expect(subject.raise_hand_enabled?).to be false }
        it { expect(subject.forum_enabled?).to be false }
        it { expect(subject.forum_only_for_trusted?).to be false }
        it { expect(subject.report_issue_enabled?).to be false }
        it { expect(subject.feedback_suggestions_enabled?).to be false }
        it { expect(subject.public?).to eq true }
        it { expect(subject.embeddable?).to eq true }
        it { expect(subject.immersive?).to eq true }
        it { expect(subject.disabled?).to eq false }
        it { expect(subject.gamification_enabled?).to eq false }
        it { expect(subject.in_preparation?).to eq true }
        it { expect(subject.teacher_training?).to eq false }

        it { expect(Mumuki::Domain::Organization::Settings.load(nil)).to be_empty }
      end
    end

    describe Mumuki::Domain::Organization::Theme do
      subject { Mumuki::Domain::Organization::Theme.parse(json[:theme]) }

      it { expect(subject.theme_stylesheet).to eq '.foo { }' }
      it { expect(subject.extension_javascript).to eq 'function foo() { }' }
    end

    describe Mumuki::Domain::Organization::Profile do
      subject { Mumuki::Domain::Organization::Profile.parse(json[:profile]) }

      it { expect(subject.logo_url).to eq 'http://mumuki.io/logo-alt-large.png' }
      it { expect(subject.contact_email).to eq 'issues@mumuki.io' }
      it { expect(subject.description).to eq 'Academy' }
      it { expect(subject.terms_of_service).to eq 'TOS' }

      it { expect(subject.locale).to eq 'en' }
      it { expect(subject.locale_json).to json_eq facebook_code: 'en_US', auth0_code: 'en', name: 'English' }
      it { expect(subject.locale_json).to be_a String }
      it { expect(subject.locale_h).to json_eq facebook_code: 'en_US', auth0_code: 'en', name: 'English' }
      it { expect(subject.locale_h).to be_a Hash }
    end

    describe Mumuki::Domain::Organization::Profile do
      subject { Mumuki::Domain::Organization::Profile.parse({}) }

      it { expect(subject.logo_url).to eq 'https://mumuki.io/logo-alt-large.png' }
      it { expect(subject.banner_url).to eq 'https://mumuki.io/logo-alt-large.png' }
      it { expect(subject.favicon_url).to eq '/favicon.ico' }
      it { expect(subject.breadcrumb_image_url).to eq nil }
      it { expect(subject.open_graph_image_url).to eq 'http://localmumuki.io/logo-alt.png' }
    end

    describe Mumuki::Domain::Organization::Profile do
      subject { Mumuki::Domain::Organization::Profile.parse(images_url_json) }
      it { expect(subject.logo_url).to eq 'http://mumuki.io/new-logo.png' }
      it { expect(subject.banner_url).to eq 'http://mumuki.io/new-logo.png' }
      it { expect(subject.favicon_url).to eq 'http://mumuki.io/new-favicon.png' }
      it { expect(subject.breadcrumb_image_url).to eq 'http://mumuki.io/new-breadcrumb-image.png' }
      it { expect(subject.open_graph_image_url).to eq 'http://mumuki.io/new-og-image.png' }
    end
  end

  describe Mumuki::Domain::Helpers::Organization do
    let(:parsed) { organization.singleton_class.parse(json) }

    describe '.parse' do
      it { expect(parsed[:name]).to eq 'test-orga' }
      it { expect(parsed[:theme]).to be_a Mumuki::Domain::Organization::Theme }
      it { expect(parsed[:settings]).to be_a Mumuki::Domain::Organization::Settings }
      it { expect(parsed[:profile]).to be_a Mumuki::Domain::Organization::Profile }
    end
    describe 'defaults' do
      it { expect(organization.private?).to be true }
      it { expect(organization.logo_url).to eq 'https://mumuki.io/logo-alt-large.png' }
      it { expect(organization.login_methods).to eq ['user_pass'] }
    end
    describe '#url_for' do
      context 'with subdomain mapping' do
        it { expect(organization.url_for 'zaraza').to eq 'http://orga.localmumuki.io/zaraza' }
        it { expect(organization.url_for '/zaraza').to eq 'http://orga.localmumuki.io/zaraza' }
      end

      context 'with path mapping' do
        before { allow_any_instance_of(Mumukit::Platform::Application::Organic).to receive(:organization_mapping).and_return(Mumukit::Platform::OrganizationMapping::Path) }

        it { expect(organization.url_for 'zaraza').to eq 'http://localmumuki.io/orga/zaraza' }
        it { expect(organization.url_for '/zaraza').to eq 'http://localmumuki.io/orga/zaraza' }
      end
    end
    describe '#retenantized_url_for' do
      context 'with subdomain mapping' do
        it { expect(organization.retenantized_url_for 'a_route/nested').to eq 'http://orga.localmumuki.io/a_route/nested' }
      end

      context 'with path mapping' do
        before { allow_any_instance_of(Mumukit::Platform::Application::Organic).to receive(:organization_mapping).and_return(Mumukit::Platform::OrganizationMapping::Path) }

        it { expect(organization.retenantized_url_for 'other_orga/a_route/nested').to eq 'http://localmumuki.io/orga/a_route/nested' }
      end
    end
    describe '#domain' do
      it { expect(organization.domain).to eq 'orga.localmumuki.io' }
    end

    describe 'to_resource_h' do
      let(:resource_h) { {
          name: 'orga',
          book: 'the/book',
          profile: {
            description: 'the description',
            terms_of_service: 'The TOS',
            community_link: 'http://link/to/community'
          },
          theme: {
            theme_stylesheet: 'css',
            extension_javascript: 'js'
          },
          settings: {
            immersive: true
          }
      } }
      it { expect(organization.to_resource_h).to json_eq resource_h }
    end

    describe '#as_json' do
      context 'when settings has unsupported attributes' do
        before { organization.settings.instance_variable_set :@saraza, 5 }

        it('they get ignored') { expect(organization.settings.as_json).not_to include('saraza') }
      end
    end
  end
end
