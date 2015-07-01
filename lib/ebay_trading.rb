require 'ebay_trading/version'
require 'ebay_trading/configuration'

module EbayTrading

  class EbayTradingError < RuntimeError; end

  class << self

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end
end
