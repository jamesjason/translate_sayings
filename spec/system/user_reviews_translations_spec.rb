require 'rails_helper'

RSpec.describe 'User reviews existing translations', type: :system do
  let!(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  it 'allows a user to review translations and reach the thank-you screen' do
    create_sample_translations

    visit contribute_path
    click_button 'Start Reviewing'

    3.times do
      current_text = find("[data-translation-review-target='sayingA']").text

      upvote = find("[data-translation-review-target='upvoteBtn']", wait: 5)
      page.execute_script('arguments[0].click();', upvote)

      expect(page).to have_no_text(current_text, wait: 5)
    end

    expect(page).to have_css("[data-translation-review-target='completeCard']", visible: true, wait: 5)
    expect(page).to have_content('Thanks for contributing!')

    click_button 'Review 10 More'

    expect(page).to have_css(
      "[data-translation-review-target='card'], [data-translation-review-target='noItemsCard']",
      visible: true,
      wait: 5
    )
  end
end
