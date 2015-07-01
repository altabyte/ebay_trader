require 'ebay_trading/request'

include EbayTrading

describe Request do

  before :all do
    @auth_token = ENV['EBAY_API_AUTH_TOKEN_TEST_USER_1']

    EbayTrading.configure do |config|
      config.environment = :sandbox
      config.ebay_site_id = 0 # ebay.com
      config.dev_id  = ENV['EBAY_API_DEV_ID_SANDBOX']
      config.app_id  = ENV['EBAY_API_APP_ID_SANDBOX']
      config.cert_id = ENV['EBAY_API_CERT_ID_SANDBOX']
    end
  end
  let(:auth_token) { @auth_token }


  describe 'GeteBayOfficialTime' do

    let(:call_name) { 'GeteBayOfficialTime' }

    it 'creates XML' do
      request = Request.new(call_name, auth_token, xml_tab_width: 2)

      puts "\n#{request.xml_request}\n"
      puts "\n#{request.to_s}\n"
    end
  end


  describe 'HTTP Timeout too short to get response' do

    let(:impossible_timeout) { 0.1 } # seconds

    it 'raises a EbayTradingTimeoutError' do
      expect { Request.new('GeteBayOfficialTime', auth_token, http_timeout: impossible_timeout) }.to raise_error EbayTradingTimeoutError
      expect { Request.new('GeteBayOfficialTime', auth_token, http_timeout: impossible_timeout) }.to raise_error EbayTradingError
      expect { Request.new('GeteBayOfficialTime', auth_token, http_timeout: impossible_timeout + 10) }.not_to raise_error
    end
  end


  describe 'GetCategories' do

    before :all do
      @request = Request.new('GetCategories', @auth_token, xml_tab_width: 2) do
        CategorySiteID 0    # eBay USA
        CategoryParent 267  # Books
        DetailLevel 'ReturnAll'
        LevelLimit 5
        ViewAllNodes 'true'
      end
    end

    subject(:request) { @request }

    it 'Prints the input and output XML' do
      puts "\n#{request.xml_request}\n"
      puts "\n#{request.to_s}\n"
    end
  end

end
