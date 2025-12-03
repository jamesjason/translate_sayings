require 'capybara/rspec'

Capybara.default_max_wait_time = 5

def chrome_options
  opts = Selenium::WebDriver::Chrome::Options.new

  # IMPORTANT: disable password leak detection popup
  opts.add_argument('--disable-features=PasswordLeakDetection')
  opts.add_argument('--disable-features=PasswordManagerOnboarding')
  opts.add_argument('--disable-notifications')
  opts.add_argument('--disable-infobars')

  # Keep viewport consistent so tests always hit the desktop nav
  opts.add_argument('--window-size=1400,1400')

  opts
end

Capybara.register_driver :selenium_chrome do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: chrome_options
  )
end

Capybara.register_driver :selenium_chrome_headless do |app|
  opts = chrome_options
  opts.add_argument('--headless=new') # modern headless

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: opts
  )
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    if ENV['SHOW_BROWSER']
      driven_by(:selenium_chrome)
    else
      driven_by(:selenium_chrome_headless)
    end
  end
end
