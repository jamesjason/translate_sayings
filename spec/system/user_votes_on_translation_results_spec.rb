require 'rails_helper'

RSpec.describe 'User votes on translation results', type: :system do
  it 'sorts results by votes after refresh' do
    login_as(create(:user), scope: :user)
    create_default_languages
    english, persian = Language.where(code: %w[en fa]).index_by(&:code).values_at('en', 'fa')
    source_saying = create(:saying, language: english, text: 'better late than never')
    create_translation(
      language1: english,
      language2: persian,
      text1: source_saying.text,
      text2: 'دیر رسیدن بهتر از هرگز نرسیدن است'
    )
    create_translation(
      language1: english,
      language2: persian,
      text1: source_saying.text,
      text2: 'یک ترجمه متفاوت'
    )

    visit root_path

    expect(page).to have_field('translation_query', wait: 5)

    find("[data-language-swap-target='targetLabel']").click
    find("[data-code='fa']").click

    within("form[action='#{translations_path}']") do
      fill_in 'translation_query', with: 'better late'
    end

    find('#translation_suggestions', visible: true, wait: 5)
    find('#translation_suggestions li', text: 'better late than never', wait: 5).click

    expect(page).to have_css("[data-test='results']", wait: 5)

    cards = all("[data-controller='vote']", wait: 5)
    expect(cards.size).to eq(2)

    card_for_translation2 = cards.find { |c| c.text.include?('یک ترجمه متفاوت') }

    card_for_translation2.find("[data-action='vote#upvote']").click
    expect(card_for_translation2).to have_text('1', wait: 5)

    visit current_url

    reordered = all("[data-controller='vote']", wait: 5)

    expect(reordered.first.text).to include('یک ترجمه متفاوت')
    expect(reordered.last.text).to include('دیر رسیدن بهتر از هرگز نرسیدن است')
  end
end
