# Tests performed on locally cached XML response files.

require 'ebay_trading/request'

include EbayTrading

describe Request do
  include FileToString # Module located in spec_helper.rb

  # Actually, configuration should not be necessary for local XML processing?
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

  describe 'Submitting a prepared XML response' do

    let(:category_id) { 19077 }  # Toys & Hobbies -> Fast Food & Cereal Premiums
    let(:response_xml) do
      self.file_to_string("#{__dir__}/xml_responses/get_categories/#{category_id}.xml")
    end

    it { expect(response_xml).not_to be_blank }

    subject(:request) do
      Request.new('GetCategories', @auth_token, xml_response: response_xml, xml_tab_width: 2) do
        CategorySiteID 0      # eBay USA
        CategoryParent 19077  # Toys & Hobbies -> Fast Food & Cereal Premiums
        DetailLevel 'ReturnAll'
        LevelLimit 5
        ViewAllNodes 'true'
      end
    end

    it { is_expected.not_to be_nil }
    it { expect(request.http_response_code).to eq(200) }
  end


  describe 'GeteBayDetails ListingStartPriceDetails' do

    let(:response_xml) do
      self.file_to_string("#{__dir__}/xml_responses/get_ebay_details/listing_start_price_details.xml")
    end

    subject(:request) do
      Request.new('GeteBayDetails', @auth_token, xml_response: response_xml, xml_tab_width: 2) do
        DetailName 'ListingStartPriceDetails'
      end
    end

    it { expect(request.http_response_code).to eq(200) }

    it 'Prints the input and output XML' do
      puts "\n#{request.xml_request}\n"
      puts "\n#{request.to_s}\n"
      puts "\n#{request.to_json_s}\n"
    end
  end
end