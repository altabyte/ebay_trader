require 'ebay_trading/request'

include EbayTrading

describe Request do

  before do
    EbayTrading.configure do |config|
      config.environment = :sandbox
      config.dev_id  = ENV['EBAY_API_DEV_ID_SANDBOX']
      config.app_id  = ENV['EBAY_API_APP_ID_SANDBOX']
      config.cert_id = ENV['EBAY_API_CERT_ID_SANDBOX']
    end
  end

  describe 'Basic no args request' do
    let(:call_name) { 'GeteBayOfficialTime' }
    let(:auth_token) { ENV['EBAY_API_AUTH_TOKEN_TEST_USER_1'] }

    it 'creates XML' do
      request = Request.new(call_name, auth_token, xml_tab_width: 2)

      puts "\n#{request.xml_request}\n"
      puts "\n#{request.xml_response}\n"
    end

  end

end