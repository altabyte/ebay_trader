require 'ebay_trading/request'

include EbayTrading

describe Request do

  # Get auth token and application key values from environmental variables.
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


  describe 'The Hello World scenario' do

    before(:all) do
      @tab_width = 2
      @call_name = 'GeteBayOfficialTime'
      @request = Request.new(@call_name, @auth_token, xml_tab_width: @tab_width)
    end

    let(:call_name) { @call_name }

    subject(:request) { @request }

    it { is_expected.not_to be_nil }
    it { is_expected.to be_success }
    it { is_expected.not_to be_failure }
    it { is_expected.not_to be_partial_failure }
    it { expect(request.http_response_code).to eq(200) }
    it { expect(request.http_timeout).to eq(EbayTrading.configuration.http_timeout) }
    it { expect(request.timestamp).not_to be_nil }
    it { expect(request.timestamp).to be_a(Time) }
    it { expect(request.call_name).to eq(call_name) }
    it { expect(request.ebay_site_id).to eq(EbayTrading.configuration.ebay_site_id) }
    it { expect(request.response_hash).to be_a(Hash) }
    it { expect(request.xml_tab_width).to eq(@tab_width) }
    it { expect(request.skip_type_casting).to be_a(Array) }
    it { expect(request.skip_type_casting).to be_empty }

    it 'should support both symbol and string keys for the response hash' do
      hash = request.response_hash
      expect(hash).to have_key('timestamp')
      expect(hash).to have_key(:timestamp)
    end

    it 'Creates request XML' do
      expect(request.xml_request).not_to be_blank
      puts "\n#{request.xml_request}\n"
    end

    it 'Stores the XML returned by eBay' do
      expect(request.to_s).not_to be_blank
      puts "\n#{request.to_s}\n"
    end

    it 'Can create pretty printed JSON' do
      puts "\n#{request.to_json_s}\n"
    end
  end


  describe 'A simple request using GetCategories' do

    before :all do
      @request = Request.new('GetCategories', @auth_token, xml_tab_width: 2) do
        CategorySiteID 0      # eBay USA
        CategoryParent 19077  # Toys & Hobbies -> Fast Food & Cereal Premiums
        DetailLevel 'ReturnAll'
        LevelLimit 5
        ViewAllNodes 'true'
      end
    end

    subject(:request) { @request }

    it 'Prints the input and output XML' do
      puts "\n#{request.xml_request}\n"
      puts "\n#{request.to_json_s}\n"
    end

    it { expect(request.http_response_code).to eq(200) }
  end


  describe 'Errors' do

    describe 'An invalid call name' do

      before(:all) do
        @call_name = 'InvalidCallName'
        @request = Request.new(@call_name, @auth_token, xml_tab_width: 2)
      end

      let(:call_name) { @call_name }

      subject(:request) { @request }

      it { is_expected.not_to be_nil }
      it { is_expected.to be_failure }
      it { is_expected.not_to be_success }
      it { is_expected.not_to be_partial_failure }
      it { expect(request.http_response_code).to eq(200) }
      it { expect(request.timestamp).not_to be_nil }
      it { expect(request.timestamp).to be_a(Time) }

      it { puts "\n#{request.to_s}\n" }
    end

    describe 'HTTP Timeout too short to get response' do

      let(:impossible_timeout) { 0.1 } # seconds

      it 'raises a EbayTradingTimeoutError' do
        expect { Request.new('GeteBayOfficialTime', auth_token, http_timeout: impossible_timeout) }.to raise_error EbayTradingTimeoutError
        expect { Request.new('GeteBayOfficialTime', auth_token, http_timeout: impossible_timeout) }.to raise_error EbayTradingError
        expect { Request.new('GeteBayOfficialTime', auth_token, http_timeout: impossible_timeout + 10) }.not_to raise_error
      end
    end
  end
end