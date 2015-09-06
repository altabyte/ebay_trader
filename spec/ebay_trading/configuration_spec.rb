require 'securerandom'

require 'ebay_trader'
require 'ebay_trader/configuration'

include EbayTrader

describe Configuration do

  subject(:config) { Configuration.new }

  describe 'Default values' do

    it { is_expected.not_to have_keys_set }
    it { expect(config.ebay_site_id).to eq(0) }
    it { expect(config.ebay_api_version).to be >= 935 }
    it { expect(config.http_timeout).to eq(30) }
    it { expect(config.price_type).to eq(:big_decimal) }

  end

  describe 'setting sandbox or production environment' do

    it { is_expected.to respond_to 'environment=' }
    it { is_expected.to respond_to 'sandbox?' }
    it { is_expected.to respond_to 'production?' }

    context 'when default settings' do
      it { is_expected.to be_sandbox }
      it { is_expected.not_to be_production }
    end

    context 'when setting production mode' do

      it 'should accept to :production symbol' do
        config.environment = :production
        expect(config).to be_production
      end

      it 'should accept to "Production" String' do
        config.environment = 'Production'
        expect(config).to be_production
      end

      it 'should revert to sandbox if sandbox is anything other than :production' do
        config.environment = :sandbox
        expect(config).to be_sandbox
        config.environment = 'random_string'
        expect(config).to be_sandbox
        config.environment = nil
        expect(config).to be_sandbox
      end
    end
  end


  describe 'URI' do

    subject(:uri) { config.uri }
    it { is_expected.not_to be_nil }
    it { is_expected.to be_a URI }

    context 'when sandbox environment' do
      it { expect(uri.to_s).to eq(Configuration::URI_SANDBOX) }
    end

    context 'when production environment' do
      let(:environment) { :production }
      before { config.environment = environment }

      it { expect(config).to be_production }
      it { expect(uri.to_s).to eq(Configuration::URI_PRODUCTION) }
    end
  end


  describe 'setting application keys' do

    it { is_expected.not_to have_keys_set }

    it 'should accept valid keys' do
      config.dev_id  = SecureRandom.uuid
      config.app_id  = SecureRandom.uuid
      config.cert_id = SecureRandom.uuid
      is_expected.to have_keys_set
    end

    it 'should raise exception to invalid keys' do
      is_expected.not_to have_keys_set
      expect { config.dev_id  = 'INVALID' }.to raise_error EbayTraderError
      expect { config.app_id  = 'INVALID' }.to raise_error EbayTraderError
      expect { config.cert_id = 'INVALID' }.to raise_error EbayTraderError
    end
  end


  describe 'Auth Tokens' do

    describe 'default' do

      context 'when no default specified' do
        it { expect(config.auth_token).to be_nil }
      end

      context 'after providing a default value' do
        let(:auth_token) { '***********_some_really_long_ebay_api_auth_token_***********' }
        before { config.auth_token = auth_token }

        it { expect(config.auth_token).not_to be_nil }
        it { expect(config.auth_token).to eq(auth_token) }
        it { expect(config.auth_token_for(Configuration::DEFAULT_AUTH_TOKEN_KEY)).to eq(auth_token) }
      end
    end


    describe 'Mapping auth tokens to eBay usernames' do

      context 'Before any auth tokens are registered' do
        it { expect(config.auth_token_for('unregistered')).to be_nil }
      end

      context 'After storing an auth token' do
        let(:key) { 'my_ebay_username' }
        let(:auth_token) { '***********_some_really_long_ebay_api_auth_token_***********' }

        before { config.map_auth_token(key, auth_token) }

        it { expect(config.auth_token_for('unregistered')).to be_nil }
        it { expect(config.auth_token_for(key)).to eq(auth_token) }
        it { expect(config.auth_token_for(key.upcase)).to eq(auth_token) }
        it { expect(config.auth_token_for(key.to_sym)).to eq(auth_token) }
      end
    end
  end


  describe 'The counter' do
    context 'Before counter is set' do
      it { expect(config).not_to have_counter }
    end

    context 'After providing a counter' do
      before do
        @count = 0
        config.counter = -> { @count += 1 }
      end

      it { expect(config).to have_counter }
      it { expect(@count).to eq(0) }

      it 'should increment the value of count' do
        config.counter_callback.call
        expect(@count).to eq(1)
        config.counter_callback.call
        expect(@count).to eq(2)
        config.counter_callback.call
        expect(@count).to eq(3)
      end
    end
  end
end
