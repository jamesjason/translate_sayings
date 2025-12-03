require 'rails_helper'

RSpec.describe 'User translates a saying', type: :system do
  before do
    create_sample_translations
  end

  it 'shows the equivalent saying in the target language (Persian) via autocomplete' do
    visit root_path
    fill_in 'translation_query', with: 'too many'

    expect(page).to have_selector('ul#translation_suggestions li', wait: 3)

    find('ul#translation_suggestions li', text: 'too many cooks spoil the broth').click
    click_button 'Translate'

    within("[data-test='results']") do
      expect(page).to have_content('Equivalent sayings in Persian')
      expect(page).to have_content('too many cooks spoil the broth')
      expect(page).to have_content('آشپز که دو تا شد آش یا شور میشه یا بی‌نمک')
    end
  end

  it 'shows the equivalent saying when languages are swapped (Persian → English)' do
    visit root_path

    find("[data-action='language-swap#swap']").click

    fill_in 'translation_query', with: 'آشپز'

    expect(page).to have_selector('ul#translation_suggestions li', wait: 3)

    find('ul#translation_suggestions li', text: 'آشپز که دو تا شد آش یا شور میشه یا بی‌نمک').click
    click_button 'Translate'

    within("[data-test='results']") do
      expect(page).to have_content('Equivalent sayings in English')
      expect(page).to have_content('آشپز که دو تا شد آش یا شور میشه یا بی‌نمک')
      expect(page).to have_content('too many cooks spoil the broth')
    end
  end
end
