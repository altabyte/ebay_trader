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


  describe 'Submitting a prepared XML response to requesting a sub-set of categories' do

    let(:call_name) { 'GetCategories' }
    let(:category_id) { 19077 }  # Toys & Hobbies -> Fast Food & Cereal Premiums
    let(:number_of_categories) { 6 }
    let(:response_xml) do
      self.file_to_string("#{__dir__}/xml_responses/get_categories/#{category_id}.xml")
    end

    it { expect(response_xml).not_to be_blank }

    subject(:request) do
      Request.new('GetCategories', @auth_token, xml_response: response_xml) do
        CategorySiteID 0      # eBay USA
        CategoryParent 19077  # Toys & Hobbies -> Fast Food & Cereal Premiums
        DetailLevel 'ReturnAll'
        LevelLimit 5
        ViewAllNodes 'true'
      end
    end

    it { is_expected.not_to be_nil }
    it { is_expected.to be_success }
    it { is_expected.not_to be_failure }
    it { is_expected.not_to be_partial_failure }
    it { is_expected.not_to have_errors }
    it { is_expected.not_to have_warnings }
    it { expect(request.http_response_code).to eq(200) }
    it { expect(request.http_timeout).to eq(EbayTrading.configuration.http_timeout) }
    it { expect(request.timestamp).not_to be_nil }
    it { expect(request.timestamp).to be_a(Time) }
    it { expect(request.call_name).to eq(call_name) }
    it { expect(request.ebay_site_id).to eq(EbayTrading.configuration.ebay_site_id) }
    it { expect(request.response_hash).to be_a(Hash) }
    it { expect(request.skip_type_casting).to be_a(Array) }
    it { expect(request.skip_type_casting).to be_empty }

    it { expect(request.response_hash).to have_key(:category_array) }
    it { expect(request.response_hash).to have_key(:category_count) }
    it { expect(request.find(:category_count)).to eq(number_of_categories) }

    it 'Should find the array of categories' do
      categories = request.find %w'category_array category'
      expect(categories).not_to be_nil
      expect(categories).to be_a(Array)
      expect(categories.count).to eq(number_of_categories)
    end

    it 'prints out a JSON report' do
      puts request.to_json_s
    end
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

    it { is_expected.not_to be_nil }
    it { is_expected.to be_success }
    it { is_expected.not_to have_errors }
    it { is_expected.not_to have_warnings }
    it { expect(request.response_hash).not_to be_nil }
    it { expect(request.response_hash).to be_a(Hash) }

    it 'Prints the input and output XML' do
      puts "\n#{request.xml_request}\n"
      puts "\n#{request.to_s}\n"
      puts "\n#{request.to_json_s}\n"
    end
  end


  describe 'Automatic type-casting' do

    let(:response_xml) do
      self.file_to_string("#{__dir__}/xml_responses/get_ebay_details/listing_start_price_details.xml")
    end

    subject(:request) do
      Request.new('GeteBayDetails', @auth_token, skip_type_casting: 'detail_version', xml_response: response_xml, xml_tab_width: 2) do
        DetailName 'ListingStartPriceDetails'
      end
    end

    let(:response_hash) { request.response_hash }

    it 'Prints the input and output XML' do
      puts "\n#{request.xml_request}\n"
      puts "\n#{request.to_s}\n"
      puts "\n#{request.to_json_s}\n"
    end

    it { is_expected.to be_success }
    it { is_expected.not_to have_errors }
    it { is_expected.not_to have_warnings }

    it { expect(response_hash).to have_key(:listing_start_price_details) }
    it { expect(response_hash).to have_key('listing_start_price_details') }

    it { expect(request.find(:listing_start_price_details)).to be_a(Array) }
    it { expect(response_hash[:listing_start_price_details]).to be_a(Array) }
    it { expect(response_hash[:listing_start_price_details].first).to be_a(Hash) }

    let(:details) { response_hash[:listing_start_price_details].first }

    it { expect(details).to be_a Hash }
    it { expect(details).to have_key(:description) }
    it { expect(details[:description]).to be_a(String) }
    it { expect(details).to have_key(:start_price) }
    it { expect(details[:start_price]).to be_a(Float) }
    it { expect(details).to have_key(:start_price_currency_id) }
    it { expect(details[:start_price_currency_id]).to be_a(String) }
    it { expect(details[:start_price_currency_id]).to eq('USD') }
    it { expect(details).to have_key(:update_time) }
    it { expect(details[:update_time]).to be_a(Time) }

    # detail_version is a Fixnum, but is included in skip_type_casting list
    it { expect(details).to have_key(:detail_version) }
    it { expect(details[:detail_version]).to be_a(String) }
  end
end