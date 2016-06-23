require 'spec_helper'

feature 'Home Flow' do
  let!(:exercise) { build(:exercise) }
  let(:guide) { create(:guide) }
  let!(:chapter) {
    create(:chapter, lessons: [
        create(:lesson, guide: guide)]) }
  let(:book) { Organization.current.book }

  before { reindex_current_organization! }

  context 'anonymous visitor' do
    scenario 'from outside' do
      Capybara.current_session.driver.header 'Referer', 'http://google.com'

      visit '/'

      expect(page).to have_text('ム mumuki')
      expect(page).to have_text(Organization.current.book.name)
    end

    scenario 'from inside' do
      Capybara.current_session.driver.header 'Referer', 'http://en.mumuki.io/exercises/1'

      visit '/'

      expect(page).to have_text('ム mumuki')
      expect(page).to have_text(Organization.current.book.name)
    end
  end

  context 'logged visitor' do
    let(:user) { create(:user) }
    before { set_current_user! user }

    context 'new user' do
      before { user.visit! nil }

      scenario 'from outside' do
        Capybara.current_session.driver.header 'Referer', 'http://google.com'

        visit '/'

        expect(page).to have_text('ム mumuki')
        expect(page).to have_text(Organization.current.book.name)
        expect(user.reload.last_organization).to eq Organization.current
      end

      scenario 'from inside' do
        Capybara.current_session.driver.header 'Referer', 'http://en.mumuki.io/exercises/1'

        visit '/'

        expect(page).to have_text('ム mumuki')
        expect(page).to have_text(Organization.current.book.name)
        expect(user.reload.last_organization).to eq Organization.current
      end
    end

    context 'recurrent user' do
      let(:other_organization) { create(:organization, name: 'virtualdojo') }
      before { user.visit! other_organization }

      scenario 'from outside' do
        Capybara.current_session.driver.header 'Referer', 'http://google.com'

        visit '/'

        expect(page).to have_text('ム mumuki')
        expect(page).to have_text(Organization.current.book.name)
        expect(user.reload.last_organization).to eq Organization.current
      end

      scenario 'from inside' do
        Capybara.current_session.driver.header 'Referer', 'http://en.mumuki.io/exercises/1'

        visit '/'

        expect(page).to have_text('ム mumuki')
        expect(page).to have_text(Organization.current.book.name)
        expect(user.reload.last_organization).to eq Organization.current
      end
    end
  end


end
