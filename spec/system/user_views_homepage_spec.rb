require 'rails_helper'

RSpec.describe 'User views homepage', type: :system do
  it 'displays the homepage layout correctly' do
    create_default_languages

    visit root_path

    expect(page).to have_content('Translate sayings')
    expect(page).to have_content('Choose your languages')
    expect(page).to have_selector("[data-language-swap-target='sourceLabel']")
    expect(page).to have_selector("[data-language-swap-target='targetLabel']")
    expect(page).to have_field('translation_query')
  end
end
