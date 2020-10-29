require 'spec_helper'

describe Organization, organization_workspace: :test do
  let(:user) { create(:user) }
  let(:central) { create(:organization, name: 'central') }

  describe '.import_from_resource_h!' do
    let(:book) { create(:book) }
    let(:resource_h) { {
      name: 'zulema',
      book: book.slug,
      profile: { locale: 'es', contact_email: 'contact@email.com' }
    } }
    let!(:imported) { Organization.import_from_resource_h! resource_h }
    let(:found) { Organization.find_by(name: 'zulema').to_resource_h }

    it { expect(imported).to_not be nil }
    it { expect(found).to json_eq resource_h, except: [:theme, :settings]  }
  end

  describe '#ask_for_help_enabled?' do
    let(:user) { create(:user) }
    let(:organization) { create(:organization) }

    context 'when non assistance medium present' do
      it { expect(organization.ask_for_help_enabled? user).to be false }
    end

    context 'when can report issues' do
      before { organization.report_issue_enabled = true }
      it { expect(organization.ask_for_help_enabled? user).to be true }
    end
    context 'when there is a community link' do
      before { organization.community_link = 'https://an-external-mumuki-forum.org' }
      it { expect(organization.ask_for_help_enabled? user).to be true }
    end

    context 'when forum is enabled' do
      before { organization.forum_enabled = true }

      context 'when user does not meet minimal permissions' do
        it { expect(organization.ask_for_help_enabled? user).to be false }
      end

      context 'when user meets minimal permissions' do
        before { user.make_student_of! organization }
        it { expect(organization.ask_for_help_enabled? user).to be true }
      end
    end
  end

  describe '.current' do
    let(:organization) { Organization.find_by(name: 'test') }
    it { expect(organization).to_not be nil }
    it { expect(organization).to eq Organization.current }
  end

  describe 'defaults' do
    let(:fresh_organization) { create(:organization, name: 'bar') }

    context 'no base organization' do
      it { expect(fresh_organization.settings.customized_login_methods?).to be true }
      it { expect(fresh_organization.theme_stylesheet).to eq nil }
    end

    context 'with base organization' do
      before { create(:base, theme_stylesheet: '.foo { width: 100%; }') }

      it { expect(fresh_organization.settings.customized_login_methods?).to be true }
      it { expect(fresh_organization.theme_stylesheet).to eq '.foo { width: 100%; }' }
    end
  end

  describe '#notify_recent_assignments!' do
    it { expect { Organization.current.notify_recent_assignments! 1.minute.ago }.to_not raise_error }
  end

  describe 'restricter_login_methods?' do
    let(:private_organization) { create(:private_organization, name: 'digitaldojo') }
    let(:public_organization) { create(:public_organization, name: 'guolok') }

    it { expect(private_organization.settings.customized_login_methods?).to be true }
    it { expect(private_organization.private?).to be true }

    it { expect { private_organization.update! public: true }.to raise_error('Validation failed: A public organization can not restrict login methods') }

    it { expect(public_organization.settings.customized_login_methods?).to be false }
    it { expect(public_organization.private?).to be false }
  end

  describe '#notify_assignments_by!' do
    it { expect { Organization.current.notify_assignments_by! user }.to_not raise_error }
  end

  describe '#in_path?' do
    let(:organization) { Organization.current }
    let!(:chapter_in_path) { create(:chapter, lessons: [
      create(:lesson, exercises: [
        create(:exercise),
        create(:exercise)
      ]),
      create(:lesson)
    ]) }
    let(:topic_in_path) { chapter_in_path.lessons.first }
    let(:topic_in_path) { chapter_in_path.topic }
    let(:lesson_in_path) { chapter_in_path.lessons.first }
    let(:guide_in_path) { lesson_in_path.guide }
    let(:exercise_in_path) { lesson_in_path.exercises.first }

    let!(:orphan_exercise) { create(:exercise) }
    let!(:orphan_guide) { orphan_exercise.guide }

    before { reindex_current_organization! }

    it 'build path properly' do
      expect(organization.in_path? orphan_guide).to be false
      expect(organization.in_path? orphan_exercise).to be false

      expect(organization.in_path? chapter_in_path).to be true
      expect(organization.in_path? topic_in_path).to be true
      expect(organization.in_path? lesson_in_path).to be true
      expect(organization.in_path? guide_in_path).to be true
    end
  end

  describe 'login_settings' do
    let(:fresh_organization) { create(:organization, name: 'foo') }
    it { expect(fresh_organization.login_settings.login_methods).to eq Mumukit::Login::Settings.default_methods }
    it { expect(fresh_organization.login_settings.social_login_methods).to eq [] }
  end

  describe 'validations' do
    let(:book) { create :book }

    context 'is valid when all is ok' do
      let(:organization) { build :public_organization }
      it { expect(organization.valid?).to be true }
    end

    context 'is invalid when there are no books' do
      let(:organization) { build :public_organization, book: nil }
      it { expect(organization.valid?).to be false }
    end

    context 'is invalid when the locale isnt known' do
      let(:organization) { build :public_organization, locale: 'uk-DA' }
      it { expect(organization.valid?).to be false }
    end

    context 'has login method' do
      let(:organization) { build :public_organization, login_methods: ['github'] }
      it { expect(organization.has_login_method? 'github').to be true }
      it { expect(organization.has_login_method? 'google').to be false }
    end

    context 'is invalid when activity range is not valid' do
      let(:organization) { build :organization, in_preparation_until: 2.minutes.since, disabled_from: 1.minute.ago }
      it { expect(organization.valid?).to be false }
    end

    context 'is valid when activity range is valid' do
      let(:organization) { build :organization, in_preparation_until: 2.minutes.ago, disabled_from: 1.minute.since }
      it { expect(organization.valid?).to be true }
    end
  end

  describe '#validate_active!' do
    context 'disabled?' do
      let(:organization) { build(:organization, disabled_from: 5.minutes.ago) }
      it { expect(organization.disabled?).to be true }
      it { expect { organization.validate_active! }.to raise_error(Mumuki::Domain::DisabledOrganizationError) }
    end

    context 'in_preparation?' do
      let(:organization) { build(:organization, in_preparation_until: 5.minutes.since) }
      it { expect(organization.in_preparation?).to be true }
      it { expect { organization.validate_active! }.to raise_error(Mumuki::Domain::UnpreparedOrganizationError) }
    end

    context 'active' do
      let(:organization) { build(:organization, disabled_from: 5.minutes.since, in_preparation_until: 2.minutes.ago) }
      it { expect(organization.in_preparation?).to be false }
      it { expect(organization.disabled?).to be false }
      it { expect { organization.validate_active! }.to_not raise_error }
    end
  end


  describe 'in_path' do
    let(:organization) { create :public_organization, name: 'main' }
    let!(:other_organization) { create :public_organization, name: 'other' }
    before { create :public_organization, name: 'other-more' }

    it 'is a relation' do
      expect(Organization.in_path Guide.new).to be_a ActiveRecord::Relation
    end

    context 'with a topic usage' do
      let(:chapter) { create(:chapter) }

      before { chapter.index_usage! organization }

      it { expect(Organization.in_path(chapter.topic).map(&:name)).to eq ['main'] }
      it { expect(organization.in_path? chapter.topic).to be true }
    end

    context 'with a guide usage' do
      let(:lesson) { create(:lesson) }

      before { lesson.index_usage! organization }

      it { expect(Organization.in_path(lesson.guide).map(&:name)).to eq ['main'] }
      it { expect(organization.in_path? lesson.guide).to be true }
    end

    context 'with a guide and topic usage with same id' do
      let(:chapter) { create(:chapter, topic: create(:topic, id: 3141516)) }
      let(:lesson) { create(:lesson, guide: create(:guide, id: 3141516)) }

      before { lesson.index_usage! organization }
      before { chapter.index_usage! other_organization }

      it { expect(Organization.in_path(lesson.guide).map(&:name)).to eq ['main'] }
      it { expect(Organization.in_path(chapter.topic).map(&:name)).to eq ['other'] }
    end

    context 'with a book usage' do
      let(:book) { create(:book) }

      before { book.index_usage! organization }

      it { expect(Organization.in_path(book).map(&:name)).to eq ['main'] }
      it { expect(organization.in_path? book).to be true }
    end
  end

  describe '#description_html' do
    let(:organization) { build(:organization, description: 'some text with *markdown*!') }

    it { expect(organization.description_html).to eq("<p>some text with <em>markdown</em>!</p>\n") }
  end

  context '#display_description_teaser_html' do
    let(:organization) { build(:organization, display_description: description) }
    context 'one paragraph' do
      let(:description) { 'some text with *markdown*!' }
      it { expect(organization.display_description_teaser_html).to eq("<p>some text with <em>markdown</em>!</p>\n") }
    end
    context 'two paragraphs' do
      let(:description) { "some text with *markdown*!\n\nand some more" }
      it { expect(organization.display_description_teaser_html).to eq("<p>some text with <em>markdown</em>!</p>\n") }
    end
  end

  describe 'page fields' do
    let(:book) { build(:book, name: 'a book', description: 'a great book') }
    let(:organization) { build(:organization, display_name: 'primaria', display_description: 'mumuki para chicos y chicas', book: book) }

    context 'when wins page' do
      before { organization.wins_page = true }
      it { expect(organization.page_name).to eq 'primaria' }
      it { expect(organization.page_description).to eq 'mumuki para chicos y chicas' }
    end

    context 'when it does not win page' do
      it { expect(organization.page_name).to eq 'a book' }
      it { expect(organization.page_description).to eq 'a great book' }
    end
  end

  describe 'display fields' do
    let(:organization) { build(:organization, name: 'primaria', description: 'mumuki para chicos y chicas') }

    it { expect(organization.name).to eq 'primaria' }
    it { expect(organization.description).to eq 'mumuki para chicos y chicas' }

    context 'with nil display_name field' do
      let(:organization) { build(:organization, name: name) }

      context 'regular organization name' do
        let(:name) { 'central' }

        it { expect(organization.display_name).to eq 'Central' }
      end

      context 'organization name with symbols' do
        let(:name) { 'some.organization-with_symbols' }

        it { expect(organization.display_name).to eq 'Some Organization With Symbols' }
      end

      context 'does not break on empty name' do
        let(:name) { nil }

        it { expect { organization.display_name }.to_not raise_error }
        it { expect(organization.display_name).to be_nil }
      end
    end

    context 'with custom display name' do
      context 'es' do
        before { I18n.locale = :es }
        before { organization.display_name = 'Mumuki Primaria'}
        it { expect(organization.display_name).to eq 'Mumuki Primaria' }
        it { expect(organization.display_description).to eq 'En este sitio encontrarás el contenido sobre programación de primaria' }
      end

      context 'en' do
        before { I18n.locale = :en }
        before { organization.display_name = 'Mumuki Primaria'}
        it { expect(organization.display_name).to eq 'Mumuki Primaria' }
        it { expect(organization.display_description).to eq 'In this site you will find programming contents about primaria' }
      end

      context 'pt' do
        before { I18n.locale = :pt }
        before { organization.display_name = 'Mumuki Primaria'}
        it { expect(organization.display_name).to eq 'Mumuki Primaria' }
        it { expect(organization.display_description).to eq 'Neste site você encontrará conteúdos de programação sobre primaria' }
      end
    end
  end

  describe '#immersible?' do
    context 'current private' do
      let(:one) { build(:organization, public: false) }
      it { expect(one.immersible?).to be false }
    end

    context 'current public, not immersible' do
      let(:one) { build(:organization, public: true) }
      it { expect(one.immersible?).to be false }
    end

    context 'current public, immersible' do
      let(:one) { build(:organization, public: true, immersible: true) }

      let(:other_immersive) { build(:organization, immersive: true) }
      let(:other_non_immersive) { build(:organization, immersive: false) }

      it { expect(one.immersible?).to be true }
      it { expect(one.immersed_in? other_immersive).to be true }
      it { expect(one.immersed_in? other_non_immersive).to be false }
    end

    context 'cannot be immersive' do
      let(:orga) { build(:organization, immersible: true) }
      before { orga.update(immersive: true) }

      it { expect(orga.valid?).to be false }
      it { expect(orga.errors[:immersible]).not_to be_nil }
    end
  end

  describe 'lookahead' do
    let(:organization) { build(:organization, name: 'foo') }

    describe '#enable_progressive_display!' do
      context 'invalid lookahead' do
        before { organization.enable_progressive_display! lookahead: 0 }
        it { expect(organization.progressive_display_lookahead).to be nil }
      end

      context 'positive lookahead' do
        before { organization.enable_progressive_display! }
        it { expect(organization.progressive_display_lookahead).to eq 1 }
      end
    end

    describe '#progressive_display=' do
      context 'nil lookahead' do
        before { organization.progressive_display_lookahead = nil }
        it { expect(organization.progressive_display_lookahead).to be nil }
      end

      context 'zero lookahead' do
        before { organization.progressive_display_lookahead = 0 }
        it { expect(organization.progressive_display_lookahead).to be nil }
      end

      context 'positive lookahead' do
        before { organization.progressive_display_lookahead = 2 }
        it { expect(organization.progressive_display_lookahead).to eq 2 }
      end

      context 'negative lookahead' do
        before { organization.progressive_display_lookahead = -1 }
        it { expect(organization.progressive_display_lookahead).to be nil }
      end

      context 'string lookahead' do
        before { organization.progressive_display_lookahead = '1' }
        it { expect(organization.progressive_display_lookahead).to be 1 }
      end
    end
  end
end
