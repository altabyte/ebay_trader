# frozen_string_literal: true

require 'ebay_trader/request'

include EbayTrader

describe Request do

  # Get auth token and application key values from environmental variables.
  before :all do
    configure_api_sandbox

    # Use a global variable to store the API call counter.
    # In a production environment you would probably want to INCR a Redis DB variable.
    $api_call_count = 0
    EbayTrader.configure do |config|
      config.counter = -> { $api_call_count += 1 }
    end
  end
  let(:auth_token) { EbayTrader.configuration.auth_token }

  it { expect($api_call_count).to eq(0) }

  describe 'The Hello World scenario' do

    before(:all) do
      @previous_api_call_count = $api_call_count
      @tab_width = 2
      @call_name = 'GeteBayOfficialTime'
      @request = Request.new(@call_name, xml_tab_width: @tab_width)
    end

    let(:call_name) { @call_name }

    subject(:request) { @request }

    it { is_expected.not_to be_nil }
    it { is_expected.to be_success }
    it { is_expected.not_to be_failure }
    it { is_expected.not_to be_partial_failure }
    it { is_expected.not_to have_errors }
    it { is_expected.not_to have_warnings }

    it 'Should increment the global variable $api_call_count' do
      expect($api_call_count).to eq(@previous_api_call_count + 1)
    end

    it { expect(request.http_response_code).to eq(200) }
    it { expect(request.http_timeout).to eq(EbayTrader.configuration.http_timeout) }
    it { expect(request.timestamp).not_to be_nil }
    it { expect(request.timestamp).to be_a(Time) }
    it { expect(request.call_name).to eq(call_name) }
    it { expect(request.ebay_site_id).to eq(EbayTrader.configuration.ebay_site_id) }
    it { expect(request.response_hash).to be_a(Hash) }
    it { expect(request.response_hash).to be_a(HashWithIndifferentAccess) }
    it { expect(request.response_hash).to respond_to :deep_find }
    it { expect(request.xml_tab_width).to eq(@tab_width) }
    it { expect(request.skip_type_casting).to be_a(Array) }
    it { expect(request.skip_type_casting).to be_empty }
    it { expect(request.known_arrays).to be_a(Array) }
    it { expect(request.known_arrays).to include('errors') }

    it {
      expect(request.response_time).to be >= 0
      puts "Request took #{request.response_time} seconds"
    }


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
      @request = Request.new('GetCategories', auth_token: @auth_token, xml_tab_width: 2) do
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

    it {
      expect(request.response_time).to be >= 0
      puts "Request took #{request.response_time} seconds"
    }
  end


  describe 'Errors' do

    describe 'An invalid call name' do

      before(:all) do
        @call_name = 'InvalidCallName'
        @request = Request.new(@call_name, xml_tab_width: 2)
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

      # Ensure that 'Errors' is an array, even though there is only 1 error
      it { expect(request.deep_find(:errors)).not_to be_nil }
      it { expect(request.deep_find(:errors)).to be_a(Array) }
      it { expect(request.deep_find(:errors).count).to eq(1) }

      it { is_expected.to have_errors }
      it { is_expected.to have_errors_or_warnings }
      it { expect(request.errors).to be_a(Array) }
      it { expect(request.errors.count).to eq(1) }
      it { expect(request.errors.first).to be_a(Struct) }

      it 'should have a severity_code' do
        expect(request.errors.first).to respond_to(:severity_code)
        expect(request.errors.first.severity_code).to eq('Error')
        expect(request.errors.first[:severity_code]).to eq('Error')
      end

      it 'should have an error code' do
        expect(request.errors.first).to respond_to(:error_code)
        expect(request.errors.first.error_code).to eq(2)
        expect(request.errors.first[:error_code]).to eq(2)
      end

      it 'should have a short message' do
        expect(request.errors.first).to respond_to(:short_message)
        expect(request.errors.first.short_message).to eq('Unsupported API call.')
        expect(request.errors.first[:short_message]).to eq('Unsupported API call.')
      end

      it { is_expected.not_to have_warnings }
      it { expect(request.warnings).to be_a(Array) }
      it { expect(request.warnings).to be_empty }

      it { puts "\n#{request.to_s}\n" }
      it { puts "\n#{request.to_json_s}\n" }
    end


    describe 'HTTP Timeout too short to get response' do

      let(:impossible_timeout) { 0.1 } # seconds

      it 'raises a EbayTraderTimeoutError' do
        expect { Request.new('GeteBayOfficialTime', auth_token: auth_token, http_timeout: impossible_timeout) }.to raise_error EbayTraderTimeoutError
        expect { Request.new('GeteBayOfficialTime', auth_token: auth_token, http_timeout: impossible_timeout) }.to raise_error EbayTraderError
        expect { Request.new('GeteBayOfficialTime', auth_token: auth_token, http_timeout: impossible_timeout + 10) }.not_to raise_error
      end
    end
  end
end
