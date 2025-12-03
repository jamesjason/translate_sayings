require 'rails_helper'

RSpec.describe 'User suggests a new translation', type: :system do
  it 'allows a user to suggest a new translation' do
    user = create(:user)
    login_as(user, scope: :user)
    english, farsi = create_default_languages

    visit contribute_path

    expect(page).to have_content('Add a New Translation')

    fill_in 'suggested_translation[source_saying_text]',
            with: 'A stitch in time saves nine'

    fill_in 'suggested_translation[target_saying_text]',
            with: 'دیر رسیدن بهتر از هرگز نرسیدن است'

    click_button 'Add Translation'

    expect(page).to have_current_path(/contribute/)

    within("[data-overlay-target='panel']") do
      expect(page).to have_css('h3', text: 'Translation added!')
      expect(page).to have_css('span.text-amber-600', text: 'Awaiting Review')
    end

    record = SuggestedTranslation.last

    expect(record).to be_present
    expect(record.user).to eq(user)
    expect(record.source_language).to eq(english)
    expect(record.target_language).to eq(farsi)

    expect(record.source_saying_text).to eq('a stitch in time saves nine')
    expect(record.target_saying_text).to eq('دیر رسیدن بهتر از هرگز نرسیدن است')

    expect(record.status).to eq('pending_review')
  end
end
