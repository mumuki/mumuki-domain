require 'spec_helper'

feature 'Search Flow' do
  let(:haskell) { create(:language, name: 'Haskell') }
  let!(:exercise) {
    create(:exercise, tag_list: ['haskell'], title: 'Foo', description: 'an awesome problem description')
  }

  scenario 'visit my submissions, when there are no submissions' do
    visit "/en/exercises/#{exercise.id}"

    click_on 'sign in with Github'

    click_on 'Submit your solution!'

    expect(page).to have_text("Submission was successfully created")
  end


end
