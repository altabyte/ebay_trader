require 'spec_helper'

describe EbayTrading do

  it 'has a version number' do
    expect(EbayTrading::VERSION).not_to be nil
  end

  describe '#configure' do

    context 'when setting production mode' do

      before do
        EbayTrading.configure { |config| config.environment = :production }
      end

      it { expect(EbayTrading.configuration).to be_production }
    end


    context 'when setting application keys from environmental variables' do

      let(:dev_id)  { ENV['EBAY_API_DEV_ID']  }
      let(:app_id)  { ENV['EBAY_API_APP_ID']  }
      let(:cert_id) { ENV['EBAY_API_CERT_ID'] }

      before do
        EbayTrading.configure do |config|
          config.dev_id  = dev_id
          config.app_id  = app_id
          config.cert_id = cert_id
        end
      end

      it { expect(EbayTrading.configuration).to have_keys_set }
    end
  end
end
