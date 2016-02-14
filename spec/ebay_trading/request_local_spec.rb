# frozen_string_literal: true

# Tests performed on locally cached XML response files.

require 'ebay_trader/request'

include EbayTrader

describe Request do
  include FileToString # Module located in spec_helper.rb

  before do
    configure_api_sandbox
  end


  describe 'Submitting a prepared XML response to requesting a sub-set of categories' do

    let(:call_name) { 'GetCategories' }
    let(:category_id) { 19077 }  # Toys & Hobbies -> Fast Food & Cereal Premiums
    let(:number_of_categories) { 6 }
    let(:response_xml) do
      self.file_to_string("#{__dir__}/xml_responses/get_categories/#{category_id}.xml")
    end

    it { expect(response_xml).not_to be_blank }

    subject(:request) do
      Request.new('GetCategories', xml_response: response_xml) do
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
    it { expect(request.http_timeout).to eq(EbayTrader.configuration.http_timeout) }
    it { expect(request.timestamp).not_to be_nil }
    it { expect(request.timestamp).to be_a(Time) }
    it { expect(request.call_name).to eq(call_name) }
    it { expect(request.ebay_site_id).to eq(EbayTrader.configuration.ebay_site_id) }
    it { expect(request.response_hash).to be_a(Hash) }
    it { expect(request.skip_type_casting).to be_a(Array) }
    it { expect(request.skip_type_casting).to be_empty }

    it { expect(request.response_hash).to have_key(:category_array) }
    it { expect(request.response_hash).to have_key(:category_count) }
    it { expect(request.deep_find(:category_count)).to eq(number_of_categories) }

    it 'Should find the array of categories' do
      categories = request.deep_find %w'category_array category'
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
      Request.new('GeteBayDetails', xml_response: response_xml, xml_tab_width: 2) do
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
      Request.new('GeteBayDetails', skip_type_casting: 'detail_version', xml_response: response_xml, xml_tab_width: 2) do
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

    it { expect(request.deep_find(:listing_start_price_details)).to be_a(Array) }
    it { expect(response_hash[:listing_start_price_details]).to be_a(Array) }
    it { expect(response_hash[:listing_start_price_details].first).to be_a(Hash) }

    let(:details) { response_hash[:listing_start_price_details].first }

    it { expect(details).to be_a Hash }
    it { expect(details).to have_key(:description) }
    it { expect(details[:description]).to be_a(String) }
    it { expect(details).to have_key(:start_price) }
    it { expect(details[:start_price]).to be_a(BigDecimal) }
    it { expect(details[:start_price]).to eq(BigDecimal.new('0.01')) }
    it { expect(details).to have_key(:start_price_currency) }
    it { expect(details[:start_price_currency]).to be_a(String) }
    it { expect(details[:start_price_currency]).to eq('USD') }
    it { expect(details).to have_key(:update_time) }
    it { expect(details[:update_time]).to be_a(Time) }

    # detail_version is a Fixnum, but is included in skip_type_casting list
    it { expect(details).to have_key(:detail_version) }
    it { expect(details[:detail_version]).to be_a(String) }
  end

  context 'When configuration price_type is set to :integer' do

    before { EbayTrader.configure { |config| config.price_type = :integer } }

    let(:response_xml) do
      self.file_to_string("#{__dir__}/xml_responses/get_ebay_details/listing_start_price_details.xml")
    end

    subject(:request) do
      Request.new('GeteBayDetails', skip_type_casting: 'detail_version', xml_response: response_xml, xml_tab_width: 2) do
        DetailName 'ListingStartPriceDetails'
      end
    end

    let(:details) { request.response_hash[:listing_start_price_details].last }

    it { expect(details[:start_price]).to be_a(Fixnum) }
    it { expect(details[:start_price]).to eq(99) }
  end


  context 'When configuration price_type is set to :money' do

    before { EbayTrader.configure { |config| config.price_type = :money } }

    let(:response_xml) do
      self.file_to_string("#{__dir__}/xml_responses/get_ebay_details/listing_start_price_details.xml")
    end

    subject(:request) do
      Request.new('GeteBayDetails', skip_type_casting: 'detail_version', xml_response: response_xml, xml_tab_width: 2) do
        DetailName 'ListingStartPriceDetails'
      end
    end

    let(:details) { request.response_hash[:listing_start_price_details].last }

    it 'should expect a Money price if Money gem installed, otherwise Fixnum' do
      if EbayTrader.is_money_gem_installed?
        expect(details[:start_price]).to be_a(Money)
        expect(details[:start_price]).to eq(Money.new(99, 'USD'))
        expect(details).not_to have_key(:start_price_currency_id)
      else
        expect(details[:start_price]).to be_a(Fixnum)
        expect(details[:start_price]).to eq(99)
        expect(details).not_to have_key(:start_price_currency_id)
        expect(details).to have_key(:start_price_currency)
      end
    end
  end
end
