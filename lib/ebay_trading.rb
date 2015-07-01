require 'ebay_trading/version'
require 'ebay_trading/configuration'

module EbayTrading

  # Generic runtime error for this gem.
  #
  class EbayTradingError < RuntimeError; end

  # The error raised when the HTTP connection times out.
  #
  # *Note:* A request can timeout and technically still succeed!
  # Consider the case when a
  # {http://developer.ebay.com/DevZone/XML/docs/Reference/ebay/AddFixedPriceItem.html AddFixedPriceItem}
  # call raises a +EbayTradingTimeoutError+. The item could have been successfully
  # uploaded, but a network issue delayed the response.
  # Hence, a +EbayTradingTimeoutError+ does not always imply the call failed.
  #
  class EbayTradingTimeoutError < EbayTradingError; end

  class << self

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end
end
