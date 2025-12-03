# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User authentication', type: :system do
  before do
    create_default_languages
  end

  it 'allows a user to sign in from the homepage' do
    create_user
    visit root_path

    within("[data-test='nav']") do
      click_link 'Sign in'
    end

    fill_in 'user_email', with: 'test@example.com'
    fill_in 'user_password', with: 'password123'
    click_button 'Sign in'

    expect(page).to have_content('Signed in successfully')

    within("[data-test='nav']") do
      expect(page).to have_link('Sign out')
      expect(page).not_to have_link('Sign in')
    end
  end

  it 'rejects invalid credentials' do
    create_user
    visit root_path

    within("[data-test='nav']") do
      click_link 'Sign in'
    end

    fill_in 'user_email', with: 'wrong@example.com'
    fill_in 'user_password', with: 'wrongpassword'
    click_button 'Sign in'

    expect(page).to have_content('Invalid Email or password')

    within("[data-test='nav']") do
      expect(page).to have_link('Sign in')
    end
  end

  it 'allows a signed-in user to sign out' do
    user = create_user
    login_as(user, scope: :user)

    visit root_path

    within("[data-test='nav']") do
      click_link 'Sign out'
    end

    expect(page).to have_content('Signed out successfully')

    within("[data-test='nav']") do
      expect(page).to have_link('Sign in')
    end
  end

  it 'allows a new user to sign up from the homepage' do
    visit root_path

    within("[data-test='nav']") do
      click_link 'Sign in'
    end

    expect(page).to have_current_path(new_user_session_path)

    click_link 'Create an account'
    fill_in 'user_email', with: 'newuser@example.com'
    fill_in 'user_password', with: 'password123'
    fill_in 'user_password_confirmation', with: 'password123'
    click_button 'Sign up'

    expect(page).to have_content('Welcome! You have signed up successfully.')

    within("[data-test='nav']") do
      expect(page).to have_link('Sign out')
      expect(page).not_to have_link('Sign in')
    end
  end

  it 'allows the user to sign in via Google OAuth' do
    mock_google_oauth(email: 'test@example.com')
    visit root_path

    within("[data-test='nav']") do
      click_link 'Sign in'
    end

    expect(page).to have_button('Sign in with Google')

    click_button 'Sign in with Google'

    expect(page).to have_content('Sign out')
    expect(User.last.email).to eq('test@example.com')
  end

  private

  def create_user
    create(:user, email: 'test@example.com', password: 'password123')
  end
end
