# frozen_string_literal: true

require 'ebay_trader/fetch_token'
require 'ebay_trader/session_id'

include EbayTrader

describe FetchToken do

  # Set +interactive+ to +true+ to launch the system browser,
  # requiring MANUAL input of the test user eBay ID and password.
  # If +false+ only the SessionID aspect will be tested.
  let(:interactive) { false }

  # This is how many seconds you have to manually log into the authentication page
  # and grant application access.
  let(:login_delay) { 45 }

  before :all do
    configure_api_sandbox
  end

  it 'Fetches an authentication token AFTER you MANUALLY log into eBay' do
    session_id = SessionID.new(xml_tab_width: 2)

    puts "\n\n#{session_id.xml_request}\n#{session_id.to_s(2)}\n\n"

    expect(session_id).not_to be_nil
    expect(session_id).to be_success

    expect(session_id.id).not_to be_blank
    puts "Session ID: #{session_id.id}"
    puts session_id.sign_in_url

    # Add some params to sign_in_url
    ru_params = { user_id: 'ABC', site: 55 }
    puts session_id.sign_in_url(ru_params)

    if interactive
      puts 'Launching system browser...'
      puts "You now have #{login_delay} seconds to MANUALLY log in and click 'I agree' to grant application access..."
      puts
      puts  session_id.sign_in_url
      puts

      case RUBY_PLATFORM
        when /linux|arch|sunos|solaris/i
          system('xdg-open', session_id.sign_in_url)
        when /darwin/i
          system('open', session_id.sign_in_url)
        when /mswin|cygwin|mingw|windows/i
          system("start #{session_id.sign_in_url}")
      end

      sleep(login_delay)

      token = FetchToken.new(session_id)
      expect(token).not_to be_nil
      expect(token).to be_success
      expect(token.auth_token).not_to be_nil
      expect(token.expiry_time).not_to be_nil
      puts
      puts "Auth Token: #{token.auth_token}"
      puts "Expires:    #{token.expiry_time}"
    end
  end
end
